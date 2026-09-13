import Foundation
import AppKit

public struct ClipboardReader {
    public init() {}

    public func readText(from pasteboard: NSPasteboard) -> String? {
        pasteboard.string(forType: .string)
    }

    public func readImage(from pasteboard: NSPasteboard) -> NSImage? {
        guard pasteboard.canReadObject(forClasses: [NSImage.self], options: nil) else { return nil }
        return pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage
    }
}
