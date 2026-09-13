import SwiftUI
import ClipboardManagerCore


struct SettingsView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var retention: RetentionPeriod
    @State private var maxItems: Int
    @State private var maxMemoryMB: Int
    @StateObject private var loginItemManager = LoginItemManager()

    init(viewModel: ClipboardViewModel) {
        self.viewModel = viewModel
        _retention = State(initialValue: viewModel.settings.retentionPeriod)
        _maxItems = State(initialValue: viewModel.settings.maxItems)
        _maxMemoryMB = State(initialValue: viewModel.settings.maxMemoryMB)
    }

    var body: some View {
        Form {
            Section("History") {
                Picker("Keep items", selection: $retention) {
                    ForEach(RetentionPeriod.allCases) { Text($0.title).tag($0) }
                }
                Stepper("Maximum items: \(maxItems)", value: $maxItems, in: 10...5000, step: 10)
                Stepper("Memory limit: \(maxMemoryMB) MB", value: $maxMemoryMB, in: 32...4096, step: 32)
            }

            Section("General") {
                Toggle("Launch Clipboard Manager at login", isOn: Binding(
                    get: { loginItemManager.isEnabled },
                    set: { loginItemManager.setEnabled($0) }
                ))
                Text("Clipboard Manager starts quietly in the menu bar when you log in to macOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Clipboard") {
                Toggle("Pause clipboard monitoring", isOn: Binding(
                    get: { viewModel.isPaused },
                    set: { _ in viewModel.togglePaused() }
                ))
                Text("History is kept in RAM only and is cleared when the app exits.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    viewModel.updateSettings(ClipboardSettings(
                        retentionPeriod: retention,
                        maxItems: maxItems,
                        maxMemoryMB: maxMemoryMB
                    ))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .padding(16)
        .frame(width: 430, height: 430)
    }
}
