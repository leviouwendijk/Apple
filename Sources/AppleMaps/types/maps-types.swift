import Macros
import Schema

@JSONSchema
public struct MapsCoordinate:
    Sendable,
    Codable,
    Hashable
{
    public let latitude: Double
    public let longitude: Double

    public init(
        latitude: Double,
        longitude: Double
    ) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

@JSONSchema
public enum MapsTransport:
    String,
    Sendable,
    Codable,
    Hashable
{
    case driving
    case cycling
    case walking
    case transit
}

/// Expected travel time and route length, as Apple Maps estimates them.
@JSONSchema
public struct MapsRoute:
    Sendable,
    Codable,
    Hashable
{
    public let seconds: Double
    public let meters: Double

    public init(
        seconds: Double,
        meters: Double
    ) {
        self.seconds = seconds
        self.meters = meters
    }
}
