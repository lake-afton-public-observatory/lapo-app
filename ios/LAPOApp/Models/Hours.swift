import Foundation

struct HoursResponse: Decodable {
    let hours: Hours

    struct Hours: Decodable {
        let prettyHours: String
        let open: String
        let close: String
    }
}
