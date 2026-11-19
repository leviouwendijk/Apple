// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Apple",
    platforms: [.macOS(.v13)],
    products: [
        // every area below, re-exported
        .library(name: "Apple", targets: ["Apple"]),

        .library(name: "AppleCalendar", targets: ["AppleCalendar"]),
        .library(name: "AppleReminders", targets: ["AppleReminders"]),
        .library(name: "AppleLocation", targets: ["AppleLocation"]),
        .library(name: "AppleWeather", targets: ["AppleWeather"]),
        .library(name: "AppleMusic", targets: ["AppleMusic"]),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Schema.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Macros.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Milieu.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Apple",
            dependencies: [
                "AppleCalendar",
                "AppleReminders",
                "AppleLocation",
                "AppleWeather",
                "AppleMusic",
            ],
            path: "Sources/Apple"
        ),

        // EventKit events
        .target(
            name: "AppleCalendar",
            dependencies: [
                .product(name: "Schema", package: "Schema"),
                .product(name: "Macros", package: "Macros"),
            ],
            path: "Sources/AppleCalendar"
        ),

        // EventKit reminders
        .target(
            name: "AppleReminders",
            dependencies: [
                .product(name: "Schema", package: "Schema"),
                .product(name: "Macros", package: "Macros"),
            ],
            path: "Sources/AppleReminders"
        ),

        // CoreLocation
        .target(
            name: "AppleLocation",
            dependencies: [
                .product(name: "Schema", package: "Schema"),
                .product(name: "Macros", package: "Macros"),
            ],
            path: "Sources/AppleLocation"
        ),

        // WeatherKit framework and REST
        .target(
            name: "AppleWeather",
            dependencies: [
                .product(name: "Schema", package: "Schema"),
                .product(name: "Macros", package: "Macros"),
                .product(name: "Milieu", package: "Milieu"),
            ],
            path: "Sources/AppleWeather"
        ),

        // Music.app over ScriptingBridge, local library, MusicKit catalog
        .target(
            name: "AppleMusic",
            dependencies: [
                "AppleMusicBridge",
                .product(name: "Schema", package: "Schema"),
                .product(name: "Macros", package: "Macros"),
            ],
            path: "Sources/AppleMusic",
            linkerSettings: [.linkedFramework("iTunesLibrary")]
        ),

        .target(
            name: "AppleMusicBridge",
            path: "Sources/AppleMusicBridge",
            publicHeadersPath: "include",
            linkerSettings: [.linkedFramework("ScriptingBridge")]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    switch target.type {
    case .regular, .executable, .test, .macro:
        var settings = target.swiftSettings ?? []
        settings.append(.treatAllWarnings(as: .error))
        settings.append(.unsafeFlags(["-continue-building-after-errors"]))
        target.swiftSettings = settings
    case .plugin, .system, .binary:
        break
    @unknown default:
        break
    }
}
