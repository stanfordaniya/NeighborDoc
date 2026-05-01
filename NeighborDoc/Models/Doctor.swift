import Foundation

struct Doctor: Identifiable, Codable, Equatable {
    var id: String            // slug/uuid
    var name: String
    var specialty: String
    var raceEthnicity: String // self-identified
    var city: String
    var state: String
    var zipCode: String       // Changed from 'zip' to 'zipCode'
    var phoneNumber: String?  // optional phone number
    var hospitalName: String? // optional hospital name
    var ownerUid: String?     // set if created by the logged-in user
    var isActive: Bool?       // visible in directory when true (nil treated as true)
}
