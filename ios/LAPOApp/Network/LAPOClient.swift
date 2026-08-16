import Foundation

protocol LAPOClientProtocol {
    func hours() async throws -> HoursResponse
    func whatsUpNext() async throws -> WhatsUpResponse
}

final class LAPOClient: LAPOClientProtocol {
    static let shared = LAPOClient()

    private let base = URL(string: "https://api.lakeafton.com/")!

    private let session: URLSession

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func hours() async throws -> HoursResponse {
        try await get("v1/hours")
    }

    func whatsUpNext() async throws -> WhatsUpResponse {
        try await get("v1/celestial/whatsup-next")
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: "\(base)\(path)") else { throw LAPOError.badResponse }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LAPOError.badResponse
        }
        return try decoder.decode(T.self, from: data)
    }
}

enum LAPOError: LocalizedError {
    case badResponse

    var errorDescription: String? {
        "Unable to reach the observatory API. Check your connection and try again."
    }
}
