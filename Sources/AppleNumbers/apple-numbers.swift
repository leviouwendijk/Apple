import Foundation

public enum AppleNumbers {
    public static func snapshot(
        at documentURL: URL
    ) throws -> NumbersSnapshot {
        guard documentURL.isFileURL else {
            throw AppleNumbersError.invalidDocumentURL(
                documentURL.absoluteString
            )
        }

        guard FileManager.default.fileExists(
            atPath: documentURL.path
        ) else {
            throw AppleNumbersError.invalidDocumentURL(
                documentURL.path
            )
        }

        let data =
            try NumbersSnapshotExtraction.extract(
                at: documentURL
            )

        return try NumbersSnapshotTransport.decode(
            data
        )
    }
}

public enum AppleNumbersError:
    Error,
    Sendable,
    CustomStringConvertible
{
    case invalidDocumentURL(String)

    case scriptFailed(
        status: Int32,
        stderr: String
    )

    case invalidSnapshotTransport(String)

    public var description: String {
        switch self {
        case .invalidDocumentURL(
            let value
        ):
            return "Invalid Numbers document URL: \(value)"

        case .scriptFailed(
            let status,
            let stderr
        ):
            return """
            Numbers scripting failed with status \(status): \
            \(stderr)
            """

        case .invalidSnapshotTransport(
            let message
        ):
            return "Invalid Numbers snapshot transport: \(message)"
        }
    }
}
