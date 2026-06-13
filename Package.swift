// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "lazytable-swiftui",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "LazyTable", targets: ["LazyTable"]),
    ],
    targets: [
        .target(name: "LazyTable"),
        .testTarget(name: "LazyTableTests", dependencies: ["LazyTable"]),
    ],
    swiftLanguageModes: [.v6]
)
