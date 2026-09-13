// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClipboardManager",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ClipboardManagerCore", targets: ["ClipboardManagerCore"]),
        .executable(name: "ClipboardManager", targets: ["ClipboardManager"])
    ],
    targets: [
        .target(name: "ClipboardManagerCore"),
        .executableTarget(name: "ClipboardManager", dependencies: ["ClipboardManagerCore"]),
        .testTarget(name: "ClipboardManagerTests", dependencies: ["ClipboardManagerCore"])
    ]
)
