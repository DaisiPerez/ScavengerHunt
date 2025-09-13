import Foundation
import CoreLocation

// add Hashable (Hashable implies Equatable, so Equatable is optional)
struct HuntTask: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var details: String
    var isCompleted: Bool
    var imageData: Data?
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        isCompleted: Bool = false,
        imageData: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.imageData = imageData
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
