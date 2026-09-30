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

    func testSkyObjectDecodesEmptyNameArrayAsUnknown() throws {
        // REGRESSION: SkyObject.init(from:) falls back to "Unknown" via
        // `names.first ?? "Unknown"` when the name array is empty -- this
        // branch had no coverage, unlike the non-empty-array and plain-string
        // cases above.
        let json = """
        {"name": [], "magnitude": 1.0}
        """.data(using: .utf8)!
        let obj = try JSONDecoder().decode(SkyObject.self, from: json)
        XCTAssertEqual(obj.name, "Unknown")
    }

    func testBrightnessLabel() {
        XCTAssertEqual(SkyObject.makeStub(magnitude: -5).brightnessLabel, "Extremely bright")
        XCTAssertEqual(SkyObject.makeStub(magnitude: -1).brightnessLabel, "Very bright")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 0.5).brightnessLabel, "Bright")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 1.5).brightnessLabel, "Average")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 5).brightnessLabel, "Dim")
    }

    func testBrightnessLabelAtExactBoundaries() {
        // Each case uses `..<upperBound`, so the boundary value itself belongs
        // to the *next* (dimmer) case, not the one it's adjacent to.
        XCTAssertEqual(SkyObject.makeStub(magnitude: -3).brightnessLabel, "Very bright")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 0).brightnessLabel, "Bright")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 1).brightnessLabel, "Average")
        XCTAssertEqual(SkyObject.makeStub(magnitude: 2).brightnessLabel, "Dim")
    }

    func testSkyObjectDecodesPresentRiseAndSetTimes() throws {
        let json = """
        {"name": "Saturn", "magnitude": 0.5, "rise_time": "20:14", "set_time": "03:47"}
        """.data(using: .utf8)!
        let obj = try JSONDecoder().decode(SkyObject.self, from: json)
        XCTAssertEqual(obj.riseTime, "20:14")
        XCTAssertEqual(obj.setTime, "03:47")
    }

    func testSkyObjectDecodesMissingRiseAndSetTimesAsNil() throws {
        let json = """
        {"name": "Saturn", "magnitude": 0.5}
        """.data(using: .utf8)!
        let obj = try JSONDecoder().decode(SkyObject.self, from: json)
        XCTAssertNil(obj.riseTime)
        XCTAssertNil(obj.setTime)
    }

    func testHoursResponseDecodesNestedHours() throws {
        let json = """
        {"hours": {"prettyHours": "7:00 PM \\u2013 11:00 PM", "open": "19:00", "close": "23:00"}}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(HoursResponse.self, from: json)
        XCTAssertEqual(response.hours.prettyHours, "7:00 PM \u{2013} 11:00 PM")
        XCTAssertEqual(response.hours.open, "19:00")
        XCTAssertEqual(response.hours.close, "23:00")
    }

    func testWhatsUpResponseDecodesSnakeCaseKeysAndObjects() throws {
        let json = """
        {
          "start_time": "2026-07-24T02:00:00Z",
          "end_time": "2026-07-24T02:01:00Z",
          "objects": [
            {"name": "Jupiter", "magnitude": -2.0, "rise_time": "21:00"},
            {"name": ["M31", "Andromeda Galaxy"], "magnitude": 3.4}
          ]
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(WhatsUpResponse.self, from: json)
        XCTAssertEqual(response.startTime, "2026-07-24T02:00:00Z")
        XCTAssertEqual(response.endTime, "2026-07-24T02:01:00Z")
        XCTAssertEqual(response.objects.count, 2)
        XCTAssertEqual(response.objects[0].name, "Jupiter")
        XCTAssertEqual(response.objects[0].riseTime, "21:00")
        XCTAssertEqual(response.objects[1].name, "M31")
        XCTAssertNil(response.objects[1].riseTime)
    }

    func testWeatherResponseDecodesOptionalFieldsWhenPresent() throws {
        let json = """
        {"temperature": {"celsius": 20, "fahrenheit": 68, "feels_like": {"celsius": 18, "fahrenheit": 64.4},
                          "min": {"celsius": 15, "fahrenheit": 59}, "max": {"celsius": 22, "fahrenheit": 71.6}},
         "wind": {"speed": {"metersPerSecond": 1, "milesPerHour": 2.24}, "direction": 180},
         "groundLevelPressure": 1013, "humidity": 50, "clouds": 10,
         "weather": [{"description": "Clear", "longDescription": "clear sky", "iconurl": "x"}],
         "visibility": {"km": 10, "mi": 6.21}, "dt": "2026-01-01T00:00:00-06:00"}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(WeatherResponse.self, from: json)
        XCTAssertEqual(response.temperature.fahrenheit, 68)
        XCTAssertEqual(response.temperature.feelsLike?.fahrenheit, 64.4)
        XCTAssertEqual(response.temperature.min?.celsius, 15)
        XCTAssertEqual(response.temperature.max?.celsius, 22)
        XCTAssertEqual(response.wind.direction, 180)
        XCTAssertEqual(response.visibility?.km, 10)
        XCTAssertEqual(response.dt, "2026-01-01T00:00:00-06:00")
        XCTAssertEqual(response.weather.first?.longDescription, "clear sky")
    }

    func testWeatherResponseDecodesWithoutOptionalFields() throws {
        // REGRESSION-SHAPED: _reshape_weather_item (lapo-api) only includes
        // feels_like/min/max/visibility/dt when specific conditions hold
        // (e.g. feels-like differs from actual temp) -- decoding must not
        // require them.
        let json = """
        {"temperature": {"celsius": 20, "fahrenheit": 68},
         "wind": {"speed": {"metersPerSecond": 1, "milesPerHour": 2.24}, "direction": null},
         "groundLevelPressure": null, "humidity": 50, "clouds": null,
         "weather": []}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(WeatherResponse.self, from: json)
        XCTAssertNil(response.temperature.feelsLike)
        XCTAssertNil(response.temperature.min)
        XCTAssertNil(response.temperature.max)
        XCTAssertNil(response.wind.direction)
        XCTAssertNil(response.groundLevelPressure)
        XCTAssertNil(response.clouds)
        XCTAssertNil(response.visibility)
        XCTAssertNil(response.dt)
        XCTAssertTrue(response.weather.isEmpty)
    }
}

private extension SkyObject {
    static func makeStub(magnitude: Double) -> SkyObject {
        let json = "{\"name\": \"Test\", \"magnitude\": \(magnitude)}".data(using: .utf8)!
        return try! JSONDecoder().decode(SkyObject.self, from: json)
    }
}
