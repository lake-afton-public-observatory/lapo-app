import XCTest
@testable import LAPOApp

final class LAPOAppTests: XCTestCase {

    func testSkyObjectDecodesStringName() throws {
        let json = """
        {"name": "Jupiter", "magnitude": -2.0}
        """.data(using: .utf8)!
        let obj = try JSONDecoder().decode(SkyObject.self, from: json)
        XCTAssertEqual(obj.name, "Jupiter")
        XCTAssertEqual(obj.magnitude, -2.0)
    }

    func testSkyObjectDecodesArrayName() throws {
        let json = """
        {"name": ["M1", "NGC1952"], "magnitude": 8.4}
        """.data(using: .utf8)!
        let obj = try JSONDecoder().decode(SkyObject.self, from: json)
        XCTAssertEqual(obj.name, "M1")
    }

    func testBrightnessLabel() {
        XCTAssertEqual(SkyObject.makeStub(magnitude: -5).brightnessLabel, "Extremely bright")
        XCTAssertEqual(SkyObject.makeStub(magnitude: -1).brightnessLabel, "Very bright")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 0.5).brightnessLabel, "Bright")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 1.5).brightnessLabel, "Average")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 5).brightnessLabel, "Dim")
    }
}

private extension SkyObject {
    static func makeStub(magnitude: Double) -> SkyObject {
        let json = "{\"name\": \"Test\", \"magnitude\": \(magnitude)}".data(using: .utf8)!
        return try! JSONDecoder().decode(SkyObject.self, from: json)
    }
}
