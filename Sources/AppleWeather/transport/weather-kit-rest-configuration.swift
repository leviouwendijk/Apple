import Foundation
import Milieu

public struct WeatherKitRESTConfiguration:
    Sendable,
    Hashable
{
    public let teamID: String
    public let keyID: String
    public let serviceID: String
    public let privateKeyPEM: String
    public let language: String
    public let timeZone: String

    public static let defaultEnvironmentPrefix = "WEATHERKIT"

    public init(
        teamID: String,
        keyID: String,
        serviceID: String,
        privateKeyPEM: String,
        language: String = "en",
        timeZone: String =
            TimeZone.autoupdatingCurrent.identifier
    ) {
        self.teamID = teamID
        self.keyID = keyID
        self.serviceID = serviceID
        self.privateKeyPEM = privateKeyPEM
        self.language = language
        self.timeZone = timeZone
    }

    /// Reads `<prefix>_TEAM_ID`, `<prefix>_KEY_ID`, `<prefix>_SERVICE_ID`
    /// and the PEM file at `<prefix>_PRIVATE_KEY_PATH`.
    public static func environment(
        prefix: String = defaultEnvironmentPrefix
    ) throws -> Self {
        let teamID = try EnvironmentExtractor.value(
            "\(prefix)_TEAM_ID"
        )
        let keyID = try EnvironmentExtractor.value(
            "\(prefix)_KEY_ID"
        )
        let serviceID = try EnvironmentExtractor.value(
            "\(prefix)_SERVICE_ID"
        )
        let privateKeyData = try EnvironmentExtractor.data(
            .symbol(
                "\(prefix)_PRIVATE_KEY_PATH"
            )
        )

        guard let privateKeyPEM = String(
            data: privateKeyData,
            encoding: .utf8
        ) else {
            throw WeatherKitRESTConfigurationError
                .invalidPrivateKeyEncoding
        }

        return .init(
            teamID: teamID,
            keyID: keyID,
            serviceID: serviceID,
            privateKeyPEM: privateKeyPEM
        )
    }
}

public enum WeatherKitRESTConfigurationError:
    Error,
    Sendable,
    LocalizedError
{
    case invalidPrivateKeyEncoding

    public var errorDescription: String? {
        switch self {
        case .invalidPrivateKeyEncoding:
            return "The WeatherKit private key file is not valid UTF-8 PEM data."
        }
    }
}
