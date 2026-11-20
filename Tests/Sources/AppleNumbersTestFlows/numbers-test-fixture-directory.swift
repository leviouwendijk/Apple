import Foundation

func numbersTestFixtureDirectory(
    prefix: String
) throws -> URL {
    let manager =
        FileManager.default

    let root =
        manager
            .temporaryDirectory
            .appendingPathComponent(
                "AppleNumbersTests",
                isDirectory: true
            )

    try manager.createDirectory(
        at: root,
        withIntermediateDirectories: true
    )

    let directory =
        root.appendingPathComponent(
            "\(prefix)-\(UUID().uuidString)",
            isDirectory: true
        )

    try manager.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )

    return directory
}
