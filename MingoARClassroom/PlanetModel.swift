import Foundation

struct Planet: Identifiable, Decodable {
    var id: String { name }
    let name: String
    let diameter: Double
    var rotationPeriod: Double
    let lengthOfDay: Double
    var distanceFromSun: Double
    var perihelion: Double
    var aphelion: Double
    var orbitalPeriod: Double
    let orbitalVelocity: Double
    let orbitalInclination: Double
    let orbitalEccentricity: Double
    let obliquityToOrbit: Double
    let planetColor: String
    let moons: [Moon]
    let rings: [Ring]
    let pointsOfInterest: [PointOfInterest]?
    var orbitalEccentricitySquared: Double { orbitalEccentricity * orbitalEccentricity }
    var orbitProgress: Float
    var rotationProgress: Float
    var completedOrbits: Int
    var completedSelfRotations: Int
}

struct Moon: Identifiable, Decodable {
    var id: String { name }
    let name: String
    let diameter: Double
    let rotationPeriod: Double
    let lengthOfDay: Double
    let distanceFromPlanet: Double
    let orbitalPeriod: Double
}

struct Ring: Decodable {
    let name: String
    let innerRadius: Double
    let outerRadius: Double
}

struct PointOfInterest: Decodable {
    let name: String
    let description: String
    let latitude: Double
    let longitude: Double
}

func loadPlanetData() -> [Planet] {
    guard let url = Bundle.main.url(forResource: "planet_data_with_moon", withExtension: "json") else {
        print("Failed to find JSON file.")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        var decodedData = try JSONDecoder().decode([String: [Planet]].self, from: data)
        guard var planets = decodedData["planets"] else { return [] }
        
        // Applying the conversions
        for (index, planet) in planets.enumerated() {
            planets[index].rotationPeriod *= 3600 // Convert hours to seconds
            planets[index].orbitalPeriod *= 86400 // Convert days to seconds
            planets[index].perihelion *= 1e6 // Convert 10^6 km to km
            planets[index].aphelion *= 1e6 // Convert 10^6 km to km
            planets[index].distanceFromSun *= 1e6 // Convert 10^6 km to km
        }
        print(planets)
        return planets
    } catch {
        print("Error decoding JSON: \(error)")
        return []
    }
}
