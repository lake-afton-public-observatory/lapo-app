import Foundation

// Mirrors lapo-api's /v1/celestial/visiblePlanets response shape
// (app/routes/celestial.py's visible_planets()) -- a bare JSON array, not
// wrapped in an object, and already filtered server-side to alt > 0.
struct VisiblePlanet: Decodable, Identifiable {
    let name: String
    let altitudeDegrees: Double
    let distanceFromEarthAU: Double
    let distanceFromEarthMiles: Double
    let magnitude: Double
    let brightness: String
    let constellation: String

    var id: String { name }
}
