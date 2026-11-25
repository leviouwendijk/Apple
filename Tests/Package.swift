// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AppleTests",
    platforms: [.macOS(.v13)],
    products: [

        .executable(name: "numberstest", targets: ["AppleNumbersTestFlows"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-tooling/TestFlows.git", branch: "master"),
        .package(path: ".."),
    ],
    targets: [

        .executableTarget(
            name: "AppleNumbersTestFlows",
            dependencies: [
                .product(name: "AppleNumbers", package: "Apple"),
                .product(name: "TestFlows", package: "TestFlows"),
            ]
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
