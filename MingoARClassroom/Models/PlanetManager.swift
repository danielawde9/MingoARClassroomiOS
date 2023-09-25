//
//  PlanetManager.swift
//  MingoARClassroom
//
//  Created by Daniel Awde on 25/09/2023.
//

import Foundation
import ARKit
import SwiftUI

class PlanetManager {
    var rotationCounts: [String: Int] = [:]
    var revolutionCounts: [String: Int] = [:]
    var speedMultiplier: Float = 86400.0
    
    // MARK: - Color Helper
    func hexStringToUIColor(hex: String) -> UIColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    // MARK: - Ambient Light
    func createAmbientLight() -> SCNNode {
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.2, alpha: 1.0) // Adjust to your desired intensity
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        return ambientNode
    }
    
    // MARK: - Sun Light
    func addSunlight(to sunNode: SCNNode) {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 2000
        light.temperature = 6500
        sunNode.light = light
    }
    
    // MARK: - AR Planet Creation
    func createARPlanet(name: String, data: Planet) -> SCNNode? {
        let diameter = CGFloat(data.diameter)
        let planet = SCNSphere(radius: diameter / 2)
        planet.segmentCount = 150
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: data.name)
        planet.materials = [material]
        
        let planetNode = SCNNode(geometry: planet)
        planetNode.name = data.name
        planetNode.position = positionOnOrbit(planet: data, angle: data.startingAngle)
        
        // If the Sun is being created, add light to it
        if data.name == "Sun" {
            addSunlight(to: planetNode)
            material.emission.contents = UIImage(named: "Sun") // Assuming the Sun's texture is named "Sun"
            planetNode.filters = addBloom()
        } else {
            let inclinationLine = createInclinationLine(for: data)
            planetNode.addChildNode(inclinationLine)
            
        }
        
        return planetNode
    }
    
    
    func addBloom() -> [CIFilter]? {
        let bloomFilter = CIFilter(name:"CIBloom")!
        bloomFilter.setValue(4.0, forKey: "inputIntensity")
        bloomFilter.setValue(4.0, forKey: "inputRadius")
        return [bloomFilter]
    }
    
    
    // MARK: - Self-Rotation
    func applySelfRotation(planetNode: SCNNode, planet: Planet) {
        let adjustedRotationPeriod = planet.rotationPeriod / speedMultiplier
        let rotationAction = SCNAction.rotateBy(x: 0, y: CGFloat(2 * Float.pi), z: 0, duration: TimeInterval(adjustedRotationPeriod))
        let rotationCompletionAction = SCNAction.run { _ in
            self.rotationCounts[planet.name, default: 0] += 1
        }
        let sequence = SCNAction.sequence([rotationAction, rotationCompletionAction])
        
        planetNode.runAction(SCNAction.repeatForever(sequence))
    }
    
    // MARK: - Revolution Animation
    func animateRevolution(planetNode: SCNNode, planet: Planet) {
        
        if planet.name == "Sun" {
            return
        }
        
        let duration = TimeInterval(planet.orbitalPeriod) / TimeInterval(speedMultiplier)
        let numberOfSteps = 360
        let startAngle = planet.startingAngle
        var actions: [SCNAction] = []
        
        for index in 0..<numberOfSteps {
            let angle = (startAngle + Float(360 * index / numberOfSteps)).truncatingRemainder(dividingBy: 360)
            let nextPosition = positionOnOrbit(planet: planet, angle: angle)
            let moveAction = SCNAction.move(to: nextPosition, duration: duration / Double(numberOfSteps))
            actions.append(moveAction)
        }
        
        let revolutionCompletionAction = SCNAction.run { _ in
            self.revolutionCounts[planet.name, default: 0] += 1
        }
        actions.append(revolutionCompletionAction)
        
        planetNode.runAction(SCNAction.repeatForever(SCNAction.sequence(actions)))
    }
    
    // MARK: - Orbit Calculation
    func calculateOrbitParameters(planet: Planet, angle: Float) -> (x: Float, y: Float, z: Float, semiMajorAxis: CGFloat, semiMinorAxis: CGFloat) {
        let radians = angle * .pi / 180.0
        let semiMajorAxis = planet.distanceFromSun
        let semiMinorAxis = semiMajorAxis * sqrt(1 - planet.orbitalEccentricitySquared)
        let eccentricAnomaly = 2 * atan(tan(radians / 2) * sqrt((1 - planet.orbitalEccentricitySquared) / (1 + planet.orbitalEccentricity)))
        let distance = semiMajorAxis * (1 - planet.orbitalEccentricitySquared) / (1 + planet.orbitalEccentricity * cos(eccentricAnomaly))
        
        let x = distance * cos(eccentricAnomaly)
        let z = distance * sin(eccentricAnomaly)
        let y = sin(eccentricAnomaly) * semiMinorAxis * tan(planet.orbitalInclination * .pi / 180.0)
        
        return (x, y, z, CGFloat(semiMajorAxis), CGFloat(semiMinorAxis))
    }
    
    // MARK: - Orbit Creation
    func createOrbitForPlanet(planet: Planet) -> SCNNode {
        var vertices: [SCNVector3] = []
        
        for angle in stride(from: 0, to: 361, by: 1) {
            vertices.append(positionOnOrbit(planet: planet, angle: Float(angle)))
        }
        
        let source = SCNGeometrySource(vertices: vertices)
        var indices: [Int32] = []
        
        for i in 0..<vertices.count - 1 {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = hexStringToUIColor(hex: planet.planetColor) // You can choose any color
        material.lightingModel = .constant // This ensures the line is always the same color regardless of lighting
        material.isDoubleSided = true
        geometry.materials = [material]
        
        return SCNNode(geometry: geometry)
    }
    
    // MARK: - Position On Orbit
    func positionOnOrbit(planet: Planet, angle: Float) -> SCNVector3 {
        let orbitParams = calculateOrbitParameters(planet: planet, angle: angle)
        return SCNVector3(orbitParams.x , orbitParams.y, orbitParams.z)
    }
    
    // MARK: - Inclination Line
    func createInclinationLine(for planet: Planet) -> SCNNode {
        let height = CGFloat(planet.diameter*1.5)
        let radius: CGFloat = 0.001  // You can adjust this to your desired thickness for the line

        let cylinder = SCNCylinder(radius: radius, height: height)
        let material = SCNMaterial()
        material.diffuse.contents = hexStringToUIColor(hex: planet.planetColor)  // Set to your desired color
        cylinder.materials = [material]

        let node = SCNNode(geometry: cylinder)
        
        // The cylinder will initially be vertical. We need to rotate it to match the planet's inclination.
        let inclinationInRadians = CGFloat(planet.obliquityToOrbit * .pi / 180.0)
        
        // Rotate the cylinder about the x-axis to match the planet's inclination.
        node.rotation = SCNVector4(1, 0, 0, inclinationInRadians)
        
        return node
    }

}
