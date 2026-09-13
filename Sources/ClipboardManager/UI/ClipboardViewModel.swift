import Foundation
import AppKit
import SwiftUI
import ClipboardManagerCore

@MainActor
final class ClipboardViewModel: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published var searchText = ""
    @Published var settings = ClipboardSettings()
    @Published var isPaused = false

    private let store = ClipboardHistoryStore()
    private let searchEngine = ClipboardSearchEngine()
    private let writer = ClipboardWriter()
    private let monitor = ClipboardMonitor()
    private var cleanupTimer: Timer?

    init() {
        monitor.onTextCopied = { [weak self] text in
            Task { @MainActor in
                guard let self, !self.isPaused else { return }
                self.store.add(text: text)
                self.refresh()
            }
        }
        monitor.onImageCopied = { [weak self] image in
            Task { @MainActor in
                guard let self, !self.isPaused else { return }
                self.store.add(image: image)
                self.refresh()
            }
        }
        monitor.start()

        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.store.removeExpiredItems()
                self?.refresh()
            }
        }
    }

    var filteredItems: [ClipboardItem] {
        searchEngine.search(query: searchText, items: items)
    }

    func select(_ item: ClipboardItem) {
        monitor.ignoreNextPasteboardChange()
        writer.write(item: item)
        store.access(id: item.id)
        refresh()
    }

    func delete(_ item: ClipboardItem) {
        store.delete(id: item.id)
        refresh()
    }

    func clear() {
        store.clear()
        refresh()
    }

    func updateSettings(_ newSettings: ClipboardSettings) {
        store.settings = newSettings
        settings = newSettings
        refresh()
    }

    func togglePaused() {
        isPaused.toggle()
    }

    private func refresh() {
        items = store.items
    }

    deinit {
        monitor.stop()
        cleanupTimer?.invalidate()
    }
}
