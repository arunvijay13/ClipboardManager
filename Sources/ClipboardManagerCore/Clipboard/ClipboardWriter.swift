import Foundation
import AppKit

public struct ClipboardWriter {
    public init() {}

    public func write(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch item.type {
        case .text:
            if let text = item.text { pasteboard.setString(text, forType: .string) }
        case .image:
            if let image = item.image { pasteboard.writeObjects([image]) }
        }
    }
}
