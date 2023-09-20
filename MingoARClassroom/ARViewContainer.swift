import SwiftUI
import ARKit

struct ARViewContainer: UIViewRepresentable {
    var selectedPlanets: [String]
    private var planetData: [Planet] = loadPlanetData()
    private let planetCreator = ARPlanetCreator()
    
    var solarSystemNode: SCNNode = SCNNode()
    
    // Initializer for the struct
    public init(selectedPlanets: [String]) {
        self.selectedPlanets = selectedPlanets
    }
    
    // Configure and return the ARSCNView
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        
        setupARConfiguration(for: arView)
        setupGestureRecognizers(for: arView, with: context)
        
        return arView
    }
    
    // Required method for UIViewRepresentable to update the ARSCNView's state
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    // Create and return the Coordinator class which will handle interactions with the ARSCNView
    func makeCoordinator() -> Coordinator {
        Coordinator(self, planetCreator: planetCreator)
    }
    
    // Set up gesture recognizers for the ARSCNView
    func setupGestureRecognizers(for arView: ARSCNView, with context: Context) {
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    // Configure the AR session to detect horizontal planes
    func setupARConfiguration(for arView: ARSCNView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
    }
    
    // The Coordinator class acts as the bridge between SwiftUI and UIKit, handling interactions and updates.
    class Coordinator: NSObject, ARSCNViewDelegate {
        
        // Reference to the parent ARViewContainer to access its properties and methods.
        var parent: ARViewContainer
        
        // A boolean to track if the solar system has been placed in the AR scene.
        var solarSystemPlaced = false
        
        // An instance of ARPlanetCreator to assist in creating and animating planets.
        var planetCreator: ARPlanetCreator
        
        // Initial scale of the solar system, used to reset after a pinch gesture.
        private var initialSolarSystemScale: SCNVector3 = SCNVector3(1, 1, 1)
        
        // Reference to the currently selected planet node.
        private var selectedPlanetNode: SCNNode?
        
        // Category masks for hit testing.
        // 1 << 1 is a bitwise operation that shifts the number 1 one position to the left, resulting in the binary number 10, which is 2 in decimal.
        // 1 << 2 shifts the number 1 two positions to the left, resulting in the binary number 100, which is 4 in decimal.
        let planetCategory: Int = 1 << 1
        let orbitCategory: Int = 1 << 2
        
        // Initializer for the Coordinator.
        init(_ parent: ARViewContainer, planetCreator: ARPlanetCreator) {
            self.parent = parent
            self.planetCreator = planetCreator
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard gesture.view != nil else { return }
            
            let scale = Float(gesture.scale)
            
            if gesture.state == .began {
                self.initialSolarSystemScale = parent.solarSystemNode.scale
            }
            
            if gesture.state == .changed {
                let newScale = SCNVector3(x: initialSolarSystemScale.x * scale,
                                          y: initialSolarSystemScale.y * scale,
                                          z: initialSolarSystemScale.z * scale)
                parent.solarSystemNode.scale = newScale
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView else { return }
            
            let location = gesture.location(in: arView)
            let hitResults = arView.hitTest(location, options: [SCNHitTestOption.categoryBitMask: planetCategory])
            
            if let tappedNode = hitResults.first?.node, tappedNode.name != nil {
                
                if tappedNode == selectedPlanetNode {
                    deselectPlanet(tappedNode)
                    selectedPlanetNode = nil
                } else {
                    if let previouslySelected = selectedPlanetNode {
                        deselectPlanet(previouslySelected)
                    }
                    selectPlanet(tappedNode)
                    selectedPlanetNode = tappedNode
                }
            }
        }
        
        func selectPlanet(_ node: SCNNode) {
            node.childNode(withName: "selectionIndicator", recursively: false)?.removeFromParentNode()
            
            let selectionIndicator = SCNSphere(radius: CGFloat(node.boundingSphere.radius + 0.02))
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.blue.withAlphaComponent(0.4)
            selectionIndicator.materials = [material]
            
            let selectionNode = SCNNode(geometry: selectionIndicator)
            selectionNode.name = "selectionIndicator"
            node.addChildNode(selectionNode)
        }
        
        func deselectPlanet(_ node: SCNNode) {
            node.childNode(withName: "selectionIndicator", recursively: false)?.removeFromParentNode()
        }
        
        // This delegate method is called when a new node has been added to the AR scene.
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard !solarSystemPlaced, let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            for planet in parent.planetData where parent.selectedPlanets.contains(planet.name) {
                if let planetNode = planetCreator.createARPlanet(name: planet.name, data: planet) { // Pass single planet
                    
                    planetCreator.applySelfRotation(planetNode: planetNode, planet: planet)
                    planetCreator.animateRevolution(planetNode: planetNode, planet: planet)
                    
                    let orbit = planetCreator.createOrbitForPlanet(planet: planet)
                    
                    planetNode.categoryBitMask = planetCategory
                    orbit.categoryBitMask = orbitCategory
                    
                    parent.solarSystemNode.addChildNode(planetNode)
                    parent.solarSystemNode.addChildNode(orbit)
                    
                }
            }
            // Add ambient light to the scene
            let ambientNode = planetCreator.createAmbientLight()
            parent.solarSystemNode.addChildNode(ambientNode)
            
            node.addChildNode(parent.solarSystemNode)
            
            solarSystemPlaced = true
        }
    }
}

class ARPlanetCreator {
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
        }
        return planetNode
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

}



// MARK: - TODOS
// without dividing perihelion and perihelion and distanceFromSun, would be the true scale of the universe we cant see the planets
// sun not glowing and lit
// color orbit not showing
// planet inclination
// planets name
// planet distance to sun
// show planet info on select
// arabic support
// planets if out of screen
// scale for the sun relative to the planet
// time
// sound
// contact , about, privacy version number
// line width
// pluto material
// ui helper
// ui sliders w hek 
