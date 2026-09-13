import AppKit
import SwiftUI
import ClipboardManagerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let viewModel = ClipboardViewModel()
    private var statusItem: NSStatusItem!
    private var historyPanel: ClipboardPanelController!
    private var settingsWindow: NSWindow?
    private var globalHotKey: GlobalHotKey?
    private let loginItemManager = LoginItemManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard Manager")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggleHistory)

        historyPanel = ClipboardPanelController(viewModel: viewModel)

        globalHotKey = GlobalHotKey(keyCode: 9, modifiers: UInt32((1 << 8) | (1 << 9))) { [weak self] in
            DispatchQueue.main.async { @MainActor [weak self] in
                self?.toggleHistory()
            }
        }

        statusItem.menu = makeStatusMenu()
    }

    @objc private func toggleHistory() {
        historyPanel.toggle()
    }

    private func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()

        let open = NSMenuItem(title: "Show Clipboard History", action: #selector(toggleHistory), keyEquivalent: "")
        open.target = self
        menu.addItem(open)

        let settings = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settings.keyEquivalentModifierMask = [.command]
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let clear = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        clear.target = self
        menu.addItem(clear)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Clipboard Manager", action: #selector(quitApp), keyEquivalent: "q")
        quit.keyEquivalentModifierMask = [.command]
        quit.target = self
        menu.addItem(quit)

        return menu
    }

    @objc private func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingView(rootView: SettingsView(viewModel: viewModel))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Clipboard Manager Settings"
        window.contentView = hosting
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    @objc private func clearHistory() {
        viewModel.clear()
    }

    @objc private func quitApp() {
        // Explicit quit action for this menu-bar-only app. Closing the history
        // or settings windows must not terminate the app; this action does.
        settingsWindow?.close()
        historyPanel?.close()
        NSApp.terminate(nil)
    }
}
