// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JadwalSolat",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "JadwalSolat",
            path: "Sources/JadwalSolat",
            exclude: ["Info.plist", "JadwalSolat.entitlements"]
        ),
        .testTarget(
            name: "JadwalSolatTests",
            dependencies: ["JadwalSolat"],
            path: "Tests/JadwalSolatTests"
        )
    ]
)
