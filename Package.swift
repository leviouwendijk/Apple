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
        .library(name: "AppleMaps", targets: ["AppleMaps"]),
        .library(name: "AppleContacts", targets: ["AppleContacts"]),
        .library(name: "AppleNumbers", targets: ["AppleNumbers"]),

        .executable(name: "numberstest", targets: ["AppleNumbersTestFlows"]),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Schema.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Macros.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Milieu.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/TestFlows.git", branch: "master"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20"),
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
                "AppleMaps",
                "AppleContacts",
                "AppleNumbers",
            ],
            path: "Sources/Apple"
        ),

        // MapKit geocoding and routing
        .target(
            name: "AppleMaps",
            dependencies: [
                .product(name: "Schema", package: "Schema"),
                .product(name: "Macros", package: "Macros"),
            ],
            path: "Sources/AppleMaps"
        ),

        // Contacts accounts, including Google over CardDAV
        .target(
            name: "AppleContacts",
            dependencies: [
                .product(name: "Schema", package: "Schema"),
                .product(name: "Macros", package: "Macros"),
            ],
            path: "Sources/AppleContacts"
        ),

        // .numbers documents read natively, and through Numbers.app scripting
        .target(
            name: "AppleNumbers",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            path: "Sources/AppleNumbers"
        ),

        .executableTarget(
            name: "AppleNumbersTestFlows",
            dependencies: [
                "AppleNumbers",
                .product(name: "TestFlows", package: "TestFlows"),
            ],
            path: "Testing/AppleNumbersTestFlows"
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
