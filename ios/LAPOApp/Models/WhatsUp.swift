import Foundation

struct WhatsUpResponse: Decodable {
    let startTime: String
    let endTime: String
    let objects: [SkyObject]

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case endTime = "end_time"
        case objects
    }
}

struct SkyObject: Decodable, Identifiable {
    // name can be a single string or array of aliases — we keep the primary
    let name: String
    let magnitude: Double
    let riseTime: String?
    let setTime: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name, magnitude
        case riseTime = "rise_time"
        case setTime = "set_time"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // name is either String or [String]
        if let names = try? c.decode([String].self, forKey: .name) {
            name = names.first ?? "Unknown"
        } else {
            name = try c.decode(String.self, forKey: .name)
        }
        magnitude = try c.decode(Double.self, forKey: .magnitude)
        riseTime = try? c.decode(String.self, forKey: .riseTime)
        setTime = try? c.decode(String.self, forKey: .setTime)
    }

    var brightnessLabel: String {
        switch magnitude {
        case ..<(-3): return "Extremely bright"
        case ..<0:    return "Very bright"
        case ..<1:    return "Bright"
        case ..<2:    return "Average"
        default:      return "Dim"
        }
    }
}
