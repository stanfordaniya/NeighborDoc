import Foundation

struct UserDoc: Codable {
    var uid: String
    var displayName: String?
    var isDoctor: Bool
    var myDoctorId: String?           // doctor profile the user owns
    var savedDoctorIds: [String]
}
