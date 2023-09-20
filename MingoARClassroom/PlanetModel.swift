import Foundation

struct Planet: Identifiable, Decodable {
    var id: String { name }
    let name: String
    var diameter: Float
    var rotationPeriod: Float
    let lengthOfDay: Float
    var distanceFromSun: Float
    var perihelion: Float
    var aphelion: Float
    var startingAngle: Float
    var orbitalPeriod: Float
    let orbitalVelocity: Float
    let orbitalInclination: Float
    let orbitalEccentricity: Float
    let obliquityToOrbit: Float
    let planetColor: String
    let moons: [Moon]
    let rings: [Ring]
    let pointsOfInterest: [PointOfInterest]?
    var orbitalEccentricitySquared: Float { orbitalEccentricity * orbitalEccentricity }
}

struct Moon: Identifiable, Decodable {
    var id: String { name }
    let name: String
    let diameter: Float
    let rotationPeriod: Float
    let lengthOfDay: Float
    let distanceFromPlanet: Float
    let orbitalPeriod: Float
}

struct Ring: Decodable {
    let name: String
    let innerRadius: Float
    let outerRadius: Float
}

struct PointOfInterest: Decodable {
    let name: String
    let description: String
    let latitude: Float
    let longitude: Float
}

func loadPlanetData() -> [Planet] {
    guard let url = Bundle.main.url(forResource: "planet_data_with_moon", withExtension: "json") else {
        print("Failed to find JSON file.")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        let decodedData = try JSONDecoder().decode([String: [Planet]].self, from: data)
        guard var planets = decodedData["planets"] else { return [] }
        
        // Applying the conversions
        for (index, planet) in planets.enumerated() {
            planets[index].rotationPeriod *= 3600 // Convert hours to seconds
            planets[index].orbitalPeriod *= 86400 // Convert days to seconds
           
            planets[index].perihelion /= 100 // Convert 10^6 km
            planets[index].aphelion /= 100 // Convert 10^6 km
            planets[index].distanceFromSun /= 100 // Convert 10^6 km
            planets[index].diameter /= 100_000 //
            
        }
        return planets
    } catch {
        print("Error decoding JSON: \(error)")
        return []
    }
}
/*
diameter in km
rotation period in hours
lenght of day also in hours
distance from sun 10^6 km
Perihelion (10^6 km)
Aphelion (10^6 km)
Orbital Period (days)
Orbital Velocity (km/s)
Orbital Inclination (degrees)
Obliquity to Orbit (degrees)
rotation speed degrees per second
*/
