import Foundation
import AppKit

public final class ClipboardHistoryStore {
    public private(set) var items: [ClipboardItem] = []
    public private(set) var currentMemoryUsage: Int = 0
    public var settings: ClipboardSettings {
        didSet {
            reapplyRetentionToExistingItems()
            enforceLimits()
        }
    }

    private let duplicateDetector = DuplicateDetector()
    private let memoryEstimator = MemoryEstimator()

    public init(settings: ClipboardSettings = ClipboardSettings()) {
        self.settings = settings
    }

    public func add(text: String) {
        guard !text.isEmpty else { return }
        if let duplicate = duplicateDetector.findDuplicate(text: text, in: items) {
            delete(id: duplicate.id)
        }
        let item = ClipboardItem(
            type: .text,
            expiresAt: expirationDate(),
            text: text,
            sizeInBytes: memoryEstimator.estimate(text: text)
        )
        items.insert(item, at: 0)
        currentMemoryUsage += item.sizeInBytes
        enforceLimits()
    }

    public func add(image: NSImage) {
        let item = ClipboardItem(
            type: .image,
            expiresAt: expirationDate(),
            image: image,
            sizeInBytes: memoryEstimator.estimate(image: image)
        )
        items.insert(item, at: 0)
        currentMemoryUsage += item.sizeInBytes
        enforceLimits()
    }

    public func delete(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        currentMemoryUsage -= items.remove(at: index).sizeInBytes
        currentMemoryUsage = max(0, currentMemoryUsage)
    }

    public func clear() {
        items.removeAll()
        currentMemoryUsage = 0
    }

    public func access(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let old = items[index]
        items[index] = ClipboardItem(
            id: old.id,
            type: old.type,
            createdAt: old.createdAt,
            lastAccessedAt: Date(),
            expiresAt: old.expiresAt,
            text: old.text,
            image: old.image,
            sizeInBytes: old.sizeInBytes
        )
    }

    public func removeExpiredItems() {
        for item in items.filter({ $0.isExpired }) {
            delete(id: item.id)
        }
    }

    private func reapplyRetentionToExistingItems() {
        let duration = settings.retentionPeriod.duration
        items = items.map { item in
            ClipboardItem(
                id: item.id,
                type: item.type,
                createdAt: item.createdAt,
                lastAccessedAt: item.lastAccessedAt,
                expiresAt: duration.map { item.createdAt.addingTimeInterval($0) },
                text: item.text,
                image: item.image,
                sizeInBytes: item.sizeInBytes
            )
        }
    }

    private func enforceLimits() {
        removeExpiredItems()
        while items.count > settings.maxItems {
            guard let last = items.last else { break }
            delete(id: last.id)
        }
        while currentMemoryUsage > settings.maxMemoryBytes {
            guard let lru = items.min(by: { $0.lastAccessedAt < $1.lastAccessedAt }) else { break }
            delete(id: lru.id)
        }
    }

    private func expirationDate() -> Date? {
        guard let duration = settings.retentionPeriod.duration else { return nil }
        return Date().addingTimeInterval(duration)
    }
}
