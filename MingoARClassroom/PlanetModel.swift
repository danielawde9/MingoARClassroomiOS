import Foundation

struct Planet:Identifiable, Decodable {
    var id: String { name }
    let name: String
    let diameter: Double
    let rotationPeriod: Double
    let lengthOfDay: Double
    let distanceFromSun: Double
    let perihelion: Double
    let aphelion: Double
    let orbitalPeriod: Double
    let orbitalVelocity: Double
    let orbitalInclination: Double
    let orbitalEccentricity: Double
    let obliquityToOrbit: Double
    let prefabName: String
    let planetColor: String
    let moons: [Moon]
    let rings: [Ring]
    let pointsOfInterest: [PointOfInterest]?
}

struct Moon: Identifiable, Decodable {
    var id: String { name }
    let name: String
    let diameter: Double
    let rotationPeriod: Double
    let lengthOfDay: Double
    let distanceFromPlanet: Double
    let orbitalPeriod: Double
    let prefabName: String
}

struct Ring: Decodable {
    let name: String
    let innerRadius: Double
    let outerRadius: Double
    let prefabName: String
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
        let decodedData = try JSONDecoder().decode([String: [Planet]].self, from: data)
        return decodedData["planets"] ?? []
    } catch {
        print("Error decoding JSON: \(error)")
        return []
    }
}
