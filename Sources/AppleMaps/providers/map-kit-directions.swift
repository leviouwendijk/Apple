import CoreLocation
import Foundation
import MapKit

/// Travel time estimates from Apple Maps routing.
public struct MapKitDirections:
    Sendable
{
    public init() {}

    /// Throws when Apple Maps finds no route or cannot be reached.
    @MainActor
    public func route(
        from origin: MapsCoordinate,
        to destination: MapsCoordinate,
        transport: MapsTransport,
        departing: Date
    ) async throws -> MapsRoute {
        let request = MKDirections.Request()
        request.source = Self.item(origin)
        request.destination = Self.item(destination)
        request.transportType = Self.transportType(transport)
        request.departureDate = departing
        let response = try await MKDirections(request: request).calculateETA()
        return .init(
            seconds: response.expectedTravelTime,
            meters: response.distance
        )
    }

    @MainActor
    private static func item(_ coordinate: MapsCoordinate) -> MKMapItem {
        if #available(macOS 26.0, *) {
            return MKMapItem(
                location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                address: nil
            )
        }
        return MKMapItem(
            placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            )
        )
    }

    private static func transportType(_ transport: MapsTransport) -> MKDirectionsTransportType {
        switch transport {
        case .driving:
            return .automobile
        case .cycling:
            return .cycling
        case .walking:
            return .walking
        case .transit:
            return .transit
        }
    }
}
