import AppKit
import SwiftUI
import CoreGraphics
import ApplicationServices
import ClipboardManagerCore

@MainActor
final class ClipboardPanelController: NSObject, NSWindowDelegate {
    private let viewModel: ClipboardViewModel
    private var panel: NSPanel!
    private var localEventMonitor: Any?
    private weak var previousApplication: NSRunningApplication?
    private var currentSelectionIndex = 0

    private let defaultSize = NSSize(width: 600, height: 680)
    private let minimumSize = NSSize(width: 500, height: 520)
    private let maximumSize = NSSize(width: 820, height: 900)

    init(viewModel: ClipboardViewModel) {
        self.viewModel = viewModel
        super.init()

        let hosting = NSHostingView(rootView: ClipboardHistoryView(
            viewModel: viewModel,
            onPaste: { [weak self] item in self?.paste(item) }
        ))

        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Clipboard History"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = false
        panel.titlebarSeparatorStyle = .line
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = hosting
        panel.minSize = minimumSize
        panel.maxSize = maximumSize
        panel.backgroundColor = .windowBackgroundColor
        panel.isOpaque = true
        panel.hasShadow = true
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, event.window === self.panel else { return event }
            switch event.keyCode {
            case 126: self.moveSelection(-1); return nil
            case 125: self.moveSelection(1); return nil
            case 36, 76: self.pasteSelected(); return nil
            case 53: self.panel.orderOut(nil); return nil
            case 51, 117:
                if self.isSearchEditorFirstResponder { return event }
                self.deleteSelected(); return nil
            default: return event
            }
        }
    }

    func close() {
        panel.orderOut(nil)
    }

    func toggle() {
        if panel.isVisible {
            panel.orderOut(nil)
            return
        }

        previousApplication = NSWorkspace.shared.frontmostApplication
        currentSelectionIndex = 0
        clampSelection()
        positionNearMouse()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        panel.orderOut(nil)
        return false
    }

    private var isSearchEditorFirstResponder: Bool {
        guard let responder = panel.firstResponder else { return false }
        return responder is NSTextView || responder is NSTextField
    }

    private var currentItems: [ClipboardItem] {
        viewModel.filteredItems
    }

    private func moveSelection(_ delta: Int) {
        let items = currentItems
        guard !items.isEmpty else { return }
        currentSelectionIndex = min(max(currentSelectionIndex + delta, 0), items.count - 1)
        NotificationCenter.default.post(
            name: .clipboardSelectionChanged,
            object: items[currentSelectionIndex].id
        )
    }

    private func pasteSelected() {
        let items = currentItems
        guard !items.isEmpty else { return }
        let index = min(max(currentSelectionIndex, 0), items.count - 1)
        paste(items[index])
    }

    /// Restore the selected item to the pasteboard, then return focus to the
    /// application where the clipboard window was opened and synthesize ⌘V.
    private func paste(_ item: ClipboardItem) {
        viewModel.select(item)
        panel.orderOut(nil)

        guard let app = previousApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }

        app.unhide()
        app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])

        // Sending ⌘V is a system-level keyboard event. macOS requires
        // Accessibility permission for this to reach another application.
        if !AXIsProcessTrustedWithOptions([
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary) {
            showAccessibilityAlert()
            return
        }

        // Give the target application time to become key before sending ⌘V.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard let source = CGEventSource(stateID: .combinedSessionState),
                  let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return }
            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Allow Clipboard Manager to paste automatically"
        alert.informativeText = "macOS needs Accessibility permission so Clipboard Manager can return to your previous app and send ⌘V. You can enable it in System Settings → Privacy & Security → Accessibility."
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func deleteSelected() {
        let items = currentItems
        guard !items.isEmpty else { return }
        let index = min(max(currentSelectionIndex, 0), items.count - 1)
        viewModel.delete(items[index])
        clampSelection()
    }

    private func clampSelection() {
        let count = currentItems.count
        currentSelectionIndex = count == 0 ? 0 : min(currentSelectionIndex, count - 1)
    }

    private func positionNearMouse() {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main else { return }
        let mouse = NSEvent.mouseLocation
        let size = panel.frame.size
        var x = mouse.x - size.width / 2
        var y = mouse.y - size.height - 18
        let visible = screen.visibleFrame
        x = min(max(x, visible.minX + 10), visible.maxX - size.width - 10)
        y = min(max(y, visible.minY + 10), visible.maxY - size.height - 10)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    deinit {
        if let monitor = localEventMonitor { NSEvent.removeMonitor(monitor) }
    }
}

extension Notification.Name {
    static let clipboardSelectionChanged = Notification.Name("ClipboardManager.clipboardSelectionChanged")
}
