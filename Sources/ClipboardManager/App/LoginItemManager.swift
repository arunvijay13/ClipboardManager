import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager: ObservableObject {
    @Published private(set) var isEnabled: Bool

    init() {
        let hasConfiguredPreference = UserDefaults.standard.bool(forKey: "launchAtLoginConfigured")

        if !hasConfiguredPreference {
            // First launch: enable the utility automatically, as requested.
            do {
                try SMAppService.mainApp.register()
            } catch {
                NSLog("Clipboard Manager initial login-item registration failed: %@", error.localizedDescription)
            }
            UserDefaults.standard.set(true, forKey: "launchAtLoginConfigured")
        }

        isEnabled = Self.currentStatusIsEnabled()
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            UserDefaults.standard.set(true, forKey: "launchAtLoginConfigured")
            isEnabled = Self.currentStatusIsEnabled()
        } catch {
            // Keep the UI in sync with the system when registration is refused.
            isEnabled = Self.currentStatusIsEnabled()
            NSLog("Clipboard Manager login item update failed: %@", error.localizedDescription)
        }
    }

    func refresh() {
        isEnabled = Self.currentStatusIsEnabled()
    }

    private static func currentStatusIsEnabled() -> Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }
}
