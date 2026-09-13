import Foundation

public struct DuplicateDetector {
    public init() {}

    public func findDuplicate(text: String, in items: [ClipboardItem]) -> ClipboardItem? {
        items.first { $0.type == .text && $0.text == text }
    }
}
