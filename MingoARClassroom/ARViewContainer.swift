import SwiftUI
import ARKit

struct ARViewContainer: UIViewRepresentable {
    var selectedPlanets: [String]
    private var planetData: [Planet] = loadPlanetData()
    private let planetCreator = ARPlanetCreator()

    var solarSystemNode: SCNNode = SCNNode()
    
    public init(selectedPlanets: [String]) {
        self.selectedPlanets = selectedPlanets
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        
        setupARConfiguration(for: arView)
        setupGestureRecognizers(for: arView, with: context)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, planetCreator: planetCreator)
    }
    
    func setupGestureRecognizers(for arView: ARSCNView, with context: Context) {
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    func setupARConfiguration(for arView: ARSCNView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        var solarSystemPlaced = false
        var planetCreator: ARPlanetCreator
        private var initialSolarSystemScale: SCNVector3 = SCNVector3(1, 1, 1)
        private var selectedPlanetNode: SCNNode?
        let planetCategory: Int = 1 << 1
        let orbitCategory: Int = 1 << 2
        
        
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
                print("Tapped on: \(tappedNode.name ?? "unknown node")")

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
            
            node.addChildNode(parent.solarSystemNode)
            
            solarSystemPlaced = true
        }
    }
}

class ARPlanetCreator {
    var earthSelfRotationCount: Int = 0
    var earthRevolutionCount: Int = 0
    var speedMultiplier: Float = 86400.0

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
    
    func createARPlanet(name: String, data: Planet) -> SCNNode? { // Accept single planet, not array
        
        let diameter = CGFloat(data.diameter)
        let planet = SCNSphere(radius: diameter / 2)
        planet.segmentCount = 550
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: data.name)
        planet.materials = [material]
        
        let planetNode = SCNNode(geometry: planet)
        planetNode.name = data.name
        let initialPosition = positionOnOrbit(planet: data, angle: 0)
        planetNode.position = initialPosition
        
        return planetNode
    }
    
    
    // 2. Self-Rotation
    func applySelfRotation(planetNode: SCNNode, planet: Planet) {
        let adjustedRotationPeriod = planet.rotationPeriod / speedMultiplier
        let rotationAction = SCNAction.rotateBy(x: 0, y: CGFloat(2 * Float.pi), z: 0, duration: TimeInterval(adjustedRotationPeriod))
        let continuousRotation = SCNAction.repeatForever(rotationAction)
        planetNode.runAction(continuousRotation)
    }
    
    
    // 3. Revolution around the Sun
    var currentAngles: [String: Float] = [:]

    func animateRevolution(planetNode: SCNNode, planet: Planet) {
        let duration = TimeInterval(planet.orbitalPeriod) / TimeInterval(speedMultiplier)
        
        let revolutionAction = SCNAction.customAction(duration: duration) { node, elapsedTime in
            let previousAngle = self.currentAngles[planet.name] ?? 0
            let deltaAngle = Float(elapsedTime) / Float(duration) * 2 * Float.pi
            let angle = previousAngle + deltaAngle
            node.position = self.positionOnOrbit(planet: planet, angle: angle)
            
            if elapsedTime >= CGFloat(duration) {
                self.currentAngles[planet.name] = angle.truncatingRemainder(dividingBy: 2 * .pi)
            }
        }
        
        let continuousRevolution = SCNAction.repeatForever(revolutionAction)
        planetNode.runAction(continuousRevolution)
    }

    
    func calculateOrbitParameters(planet: Planet, angle: Float) -> (x: Float, y: Float, z: Float, semiMajorAxis: CGFloat, semiMinorAxis: CGFloat) {
        let radians = angle * .pi / 180.0
        
        let semiMajorAxis = planet.distanceFromSun
        let semiMinorAxis = semiMajorAxis * sqrt(1 - planet.orbitalEccentricitySquared)
        
        let eccentricAnomaly = 2 * atan(tan(radians / 2) * sqrt((1 - planet.orbitalEccentricitySquared) / (1 + planet.orbitalEccentricity)))
        let distance = semiMajorAxis * (1 - planet.orbitalEccentricitySquared) / (1 + planet.orbitalEccentricity * cos(eccentricAnomaly))
        
        let x = distance * cos(eccentricAnomaly)
        let z = distance * sin(eccentricAnomaly)
        
        // Apply the orbital inclination
        let y = sin(eccentricAnomaly) * semiMinorAxis * tan(planet.orbitalInclination * .pi / 180.0)
        
        
        return (x, y, z, CGFloat(semiMajorAxis), CGFloat(semiMinorAxis))
    }
    
    func createOrbitForPlanet(planet: Planet) -> SCNNode {
        var vertices: [SCNVector3] = []
        
        // Iterate over angles and compute orbit positions
        for angle in stride(from: 0, to: 360, by: 1) {
            let position = positionOnOrbit(planet: planet, angle: Float(angle))
            vertices.append(position)
        }
        
        // Create a geometry source from the vertices
        let source = SCNGeometrySource(vertices: vertices)
        
        // Create geometry elements for the source
        var indices: [Int32] = []
        for i in 0..<vertices.count - 1 {
            indices.append(Int32(i))
            indices.append(Int32(i + 1))
        }
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        // Create the geometry and the node
        let geometry = SCNGeometry(sources: [source], elements: [element])
        
        return SCNNode(geometry: geometry)
    }
    
    
    
    func positionOnOrbit(planet: Planet, angle: Float) -> SCNVector3 {
        let orbitParams = calculateOrbitParameters(planet: planet, angle: angle)
        if planet.name == "Earth" {
//            print("Earth x: \(orbitParams.x), y: \(orbitParams.y), z: \(orbitParams.z)")
        }
        return SCNVector3(orbitParams.x , orbitParams.y, orbitParams.z)
    }
    
}

