import Foundation

public struct ClipboardSearchEngine {
    public init() {}

    public func search(query: String, items: [ClipboardItem]) -> [ClipboardItem] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return items }
        return items.filter {
            guard $0.type == .text, let text = $0.text else { return false }
            return text.localizedCaseInsensitiveContains(query)
        }
    }
}
