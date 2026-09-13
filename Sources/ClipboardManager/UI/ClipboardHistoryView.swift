import SwiftUI
import AppKit
import ClipboardManagerCore

struct ClipboardHistoryView: View {
    @ObservedObject var viewModel: ClipboardViewModel
    let onPaste: (ClipboardItem) -> Void
    @FocusState private var searchFocused: Bool
    @State private var selectedID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            content
            footer
        }
        .frame(minWidth: 500, minHeight: 520)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.primary.opacity(0.14), lineWidth: 0.8)
        }
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        }
        .onAppear {
            searchFocused = true
            selectedID = viewModel.filteredItems.first?.id
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipboardSelectionChanged)) { note in
            if let id = note.object as? UUID { selectedID = id }
        }
        .onChange(of: viewModel.searchText) { _ in
            if let id = selectedID, !viewModel.filteredItems.contains(where: { $0.id == id }) {
                selectedID = viewModel.filteredItems.first?.id
            }
        }
        .onChange(of: viewModel.items.map(\.id)) { _ in
            if selectedID == nil || !viewModel.filteredItems.contains(where: { $0.id == selectedID }) {
                selectedID = viewModel.filteredItems.first?.id
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.tint.opacity(0.12))
                Image(systemName: "clipboard.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.tint)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("Clipboard History")
                    .font(.system(size: 17, weight: .semibold))
                Text("Click an item to paste")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(viewModel.filteredItems.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.quaternary, in: Capsule())

            Button(action: viewModel.clear) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Clear history")
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 13)
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search clipboard", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($searchFocused)

            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            } else {
                Text("⌘⇧V")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 40)
        .background(.quaternary.opacity(0.65), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(searchFocused ? Color.accentColor.opacity(0.45) : .primary.opacity(0.07), lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 13)
    }

    private var content: some View {
        Group {
            if viewModel.filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.searchText.isEmpty ? "clipboard" : "magnifyingglass")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text(viewModel.searchText.isEmpty ? "Your clipboard is empty" : "No matching items")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(viewModel.searchText.isEmpty ? "Copy text or an image to start building history." : "Try a different search term.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(30)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 7) {
                            ForEach(viewModel.filteredItems) { item in
                                ClipboardItemRow(
                                    item: item,
                                    isSelected: selectedID == item.id,
                                    onPaste: {
                                        selectedID = item.id
                                        onPaste(item)
                                    },
                                    onDelete: { viewModel.delete(item) }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .scrollIndicators(.automatic)
                    .onChange(of: selectedID) { id in
                        if let id { withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(id, anchor: .center) } }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            ShortcutHint(symbol: "↑↓", label: "Navigate")
            ShortcutHint(symbol: "↵", label: "Paste")
            ShortcutHint(symbol: "⌫", label: "Delete")
            Spacer()
            Text("Click to paste")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

private struct ShortcutHint: View {
    let symbol: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(symbol)
                .font(.caption2.weight(.semibold))
            Text(label)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onPaste: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 13) {
            preview

            VStack(alignment: .leading, spacing: 5) {
                if item.type == .text {
                    Text(item.text ?? "")
                        .lineLimit(3)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                        Text("Image")
                    }
                    .font(.system(size: 14, weight: .medium))
                }

                HStack(spacing: 7) {
                    Text(item.createdAt, style: .relative)
                    Text("•")
                    Text(item.type == .text ? "Text" : "Image")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            if isHovered || isSelected {
                Button(action: onPaste) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .help("Paste")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Delete")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.55) : .primary.opacity(isHovered ? 0.10 : 0.04), lineWidth: isSelected ? 1.2 : 0.7)
        }
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .onHover { isHovered = $0 }
        .onTapGesture(perform: onPaste)
        .help("Paste this item")
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private var rowBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor.opacity(0.10))
        }
        if isHovered {
            return AnyShapeStyle(.quaternary.opacity(0.75))
        }
        return AnyShapeStyle(.primary.opacity(0.035))
    }

    @ViewBuilder private var preview: some View {
        switch item.type {
        case .text:
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.tint.opacity(isSelected ? 0.15 : 0.09))
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.tint)
            }
            .frame(width: 44, height: 44)
        case .image:
            if let image = item.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(.primary.opacity(0.08), lineWidth: 0.7)
                    }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous).fill(.quaternary)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 72, height: 52)
            }
        }
    }
}
