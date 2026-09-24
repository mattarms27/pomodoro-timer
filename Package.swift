// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PomodoroTimer",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "PomodoroTimer",
            path: "Sources/PomodoroTimer",
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        )
    ]
)
