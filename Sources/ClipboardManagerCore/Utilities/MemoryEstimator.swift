import Foundation
import AppKit

public struct MemoryEstimator {
    public init() {}

    public func estimate(text: String) -> Int {
        max(text.utf8.count, 1)
    }

    public func estimate(image: NSImage) -> Int {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return 1 }
        let width = max(bitmap.pixelsWide, 1)
        let height = max(bitmap.pixelsHigh, 1)
        return max(width * height * 4, tiff.count)
    }
}
