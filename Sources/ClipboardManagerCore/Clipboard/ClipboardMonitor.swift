import Foundation
import AppKit

public final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private let reader = ClipboardReader()
    private var timer: Timer?
    private var lastChangeCount: Int
    private var ignoredChangeCount: Int?

    public var onTextCopied: ((String) -> Void)?
    public var onImageCopied: ((NSImage) -> Void)?

    public init() {
        lastChangeCount = pasteboard.changeCount
    }

    public func start() {
        stop()
        let timer = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Call immediately before this app writes to NSPasteboard. The resulting
    /// change is ignored so restoring an item does not create a duplicate.
    public func ignoreNextPasteboardChange() {
        ignoredChangeCount = pasteboard.changeCount + 1
    }

    private func checkClipboard() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        if ignoredChangeCount == current {
            ignoredChangeCount = nil
            return
        }
        ignoredChangeCount = nil

        // Prefer images when the pasteboard contains both an image and a
        // textual representation (common with screenshots/rich content).
        if let image = reader.readImage(from: pasteboard) {
            onImageCopied?(image)
            return
        }

        if let text = reader.readText(from: pasteboard), !text.isEmpty {
            onTextCopied?(text)
        }
    }

    deinit { stop() }
}
