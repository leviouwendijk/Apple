import Foundation

enum NumbersScriptRunner {
    static func runJavaScript(
        _ source: String,
        arguments: [String]
    ) throws -> Data {
        let fileManager =
            FileManager.default

        let directory =
            fileManager
                .temporaryDirectory
                .appendingPathComponent(
                    "AppleNumbers-\(UUID().uuidString)",
                    isDirectory: true
                )

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(
                at: directory
            )
        }

        let scriptURL =
            directory.appendingPathComponent(
                "snapshot.js"
            )

        let stdoutURL =
            directory.appendingPathComponent(
                "stdout"
            )

        let stderrURL =
            directory.appendingPathComponent(
                "stderr"
            )

        try source.write(
            to: scriptURL,
            atomically: true,
            encoding: .utf8
        )

        try Data().write(
            to: stdoutURL
        )

        try Data().write(
            to: stderrURL
        )

        let stdoutHandle =
            try FileHandle(
                forWritingTo: stdoutURL
            )

        let stderrHandle =
            try FileHandle(
                forWritingTo: stderrURL
            )

        let process = Process()

        process.executableURL = URL(
            fileURLWithPath:
                "/usr/bin/osascript"
        )

        process.arguments = [
            "-l",
            "JavaScript",
            scriptURL.path,
        ] + arguments

        process.standardOutput =
            stdoutHandle

        process.standardError =
            stderrHandle

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            try? stdoutHandle.close()
            try? stderrHandle.close()

            throw error
        }

        try stdoutHandle.close()
        try stderrHandle.close()

        let stdout = try Data(
            contentsOf: stdoutURL
        )

        let stderr = try Data(
            contentsOf: stderrURL
        )

        guard process.terminationStatus == 0 else {
            throw AppleNumbersError.scriptFailed(
                status:
                    process.terminationStatus,
                stderr:
                    String(
                        data: stderr,
                        encoding: .utf8
                    )
                    ?? "<non-UTF8 stderr>"
            )
        }

        return stdout
    }
}
