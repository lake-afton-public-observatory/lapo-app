import Foundation

// Mirrors lapo-api's `_reshape_weather_item()` output shape
// (app/services/weather_api.py) for GET /v1/weather/current.
struct WeatherResponse: Decodable {
    struct TempPair: Decodable {
        let celsius: Double
        let fahrenheit: Double
    }

    struct Temperature: Decodable {
        let celsius: Double
        let fahrenheit: Double
        // Only present when the reshaper computes a feels-like temp that
        // differs from the actual temp -- see _reshape_weather_item's
        // `if fl != temp_c` check.
        let feelsLike: TempPair?
        // Only present when the API's min/max differ from each other.
        let min: TempPair?
        let max: TempPair?

        enum CodingKeys: String, CodingKey {
            case celsius, fahrenheit
            case feelsLike = "feels_like"
            case min, max
        }
    }

    struct WindSpeed: Decodable {
        let metersPerSecond: Double
        let milesPerHour: Double
    }

    struct Wind: Decodable {
        let speed: WindSpeed
        let direction: Int?
    }

    struct Condition: Decodable {
        let description: String
        let longDescription: String
        let iconurl: String
    }

    struct Visibility: Decodable {
        let km: Double
        let mi: Double
    }

    let temperature: Temperature
    let wind: Wind
    let groundLevelPressure: Double?
    let humidity: Int
    let clouds: Int?
    let weather: [Condition]
    // Only present when OpenWeatherMap's raw response includes it.
    let visibility: Visibility?
    // Only present when a `tz` query param was passed to the route.
    let dt: String?
}
