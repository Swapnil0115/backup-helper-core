// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BackupHelperCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "BackupHelperCore", targets: ["BackupHelperCore"]),
    ],
    // No dependencies, on purpose.
    dependencies: [],
    targets: [
        .target(name: "BackupHelperCore"),
        .testTarget(name: "BackupHelperCoreTests", dependencies: ["BackupHelperCore"]),
    ]
)
