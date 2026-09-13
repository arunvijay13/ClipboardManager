import Foundation
import AppKit

public enum ClipboardItemType: Equatable {
    case text
    case image
}

public struct ClipboardItem: Identifiable {
    public let id: UUID
    public let type: ClipboardItemType
    public let createdAt: Date
    public var lastAccessedAt: Date
    public let expiresAt: Date?
    public let text: String?
    public let image: NSImage?
    public let sizeInBytes: Int

    public init(
        id: UUID = UUID(),
        type: ClipboardItemType,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        expiresAt: Date? = nil,
        text: String? = nil,
        image: NSImage? = nil,
        sizeInBytes: Int = 0
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.expiresAt = expiresAt
        self.text = text
        self.image = image
        self.sizeInBytes = sizeInBytes
    }

    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt
    }
}
