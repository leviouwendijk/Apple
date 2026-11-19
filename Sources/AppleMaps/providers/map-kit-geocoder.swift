import CoreLocation
import Foundation
import MapKit

/// Address text to coordinates through Apple's geocoder.
public struct MapKitGeocoder:
    Sendable
{
    public init() {}

    /// The best match's coordinate; nil when the text finds nothing.
    @MainActor
    public func coordinate(
        of text: String
    ) async throws -> MapsCoordinate? {
        let found: CLLocationCoordinate2D?
        do {
            if #available(macOS 26.0, *) {
                guard let request = MKGeocodingRequest(addressString: text) else {
                    return nil
                }
                found = try await request.mapItems.first?.location.coordinate
            } else {
                found = try await CLGeocoder().geocodeAddressString(text).first?.location?.coordinate
            }
        } catch let error as CLError where error.code == .geocodeFoundNoResult || error.code == .geocodeFoundPartialResult {
            return nil
        } catch let error as MKError where error.code == .placemarkNotFound {
            return nil
        }
        return found.map {
            .init(latitude: $0.latitude, longitude: $0.longitude)
        }
    }
}
