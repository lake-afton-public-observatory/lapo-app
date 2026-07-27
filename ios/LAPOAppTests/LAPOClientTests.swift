import XCTest
@testable import LAPOApp

private final class URLProtocolMock: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var capturedURL: URL?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        URLProtocolMock.capturedURL = request.url
        guard let handler = URLProtocolMock.requestHandler else {
            fatalError("URLProtocolMock.requestHandler not set")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class LAPOClientTests: XCTestCase {

    private func makeClient() -> LAPOClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return LAPOClient(session: URLSession(configuration: config))
    }

    override func tearDown() {
        URLProtocolMock.requestHandler = nil
        URLProtocolMock.capturedURL = nil
        super.tearDown()
    }

    func testHoursDecodesA200Response() async throws {
        let json = """
        {"hours": {"prettyHours": "7:00 PM \\u2013 11:00 PM", "open": "19:00", "close": "23:00"}}
        """.data(using: .utf8)!

        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let result = try await makeClient().hours()

        XCTAssertEqual(result.hours.open, "19:00")
        XCTAssertEqual(result.hours.close, "23:00")
        XCTAssertTrue(URLProtocolMock.capturedURL?.absoluteString.hasSuffix("v1/hours") ?? false)
    }

    func testWhatsUpNextHitsTheCorrectPath() async throws {
        let json = """
        {"start_time": "2026-01-01T00:00:00Z", "end_time": "2026-01-01T00:01:00Z", "objects": []}
        """.data(using: .utf8)!

        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        _ = try await makeClient().whatsUpNext()

        XCTAssertTrue(URLProtocolMock.capturedURL?.absoluteString.hasSuffix("v1/celestial/whatsup-next") ?? false)
    }

    func testHoursThrowsBadResponseOnNon200Status() async throws {
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await makeClient().hours()
            XCTFail("Expected badResponse to be thrown")
        } catch is LAPOError {
            // expected
        }
    }

    func testHoursThrowsOnMalformedJSONEvenWithA200Status() async throws {
        // REGRESSION-SHAPED: a 200 status alone doesn't guarantee decodable
        // data -- the decode step must still surface its own error rather
        // than silently producing a garbage HoursResponse.
        URLProtocolMock.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }

        do {
            _ = try await makeClient().hours()
            XCTFail("Expected a decoding error to be thrown")
        } catch is DecodingError {
            // expected
        }
    }
}
