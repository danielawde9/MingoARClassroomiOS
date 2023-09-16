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
            let hitResults = arView.hitTest(location, options: nil)
            
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

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard !solarSystemPlaced, let planeAnchor = anchor as? ARPlaneAnchor else { return }

            let planets = parent.planetData.filter { parent.selectedPlanets.contains($0.name) }.compactMap {
                planetCreator.createARPlanet(name: $0.name, data: parent.planetData)
            }

            for planet in parent.planetData where parent.selectedPlanets.contains(planet.name) {
                if let arPlanet = planetCreator.createARPlanet(name: planet.name, data: parent.planetData) {
                    
                    // Convert planet's distanceFromSun to an appropriate scale
                    let distanceFromSunInScene = Float(planet.distanceFromSun) / 1000.0
                    arPlanet.position = SCNVector3(distanceFromSunInScene, 0, planeAnchor.center.z)
                    parent.solarSystemNode.addChildNode(arPlanet)
                    
                    // Create and apply rotation action
                    let rotationDuration = planet.orbitalPeriod / 10.0 // for faster visualization, adjust as needed
                    let rotateAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi * 2, around: SCNVector3(0, 1, 0), duration: rotationDuration))
                    arPlanet.runAction(rotateAction)
                    
                    // Create orbit (just a visual representation, not for actual rotation)
                    let orbit = planetCreator.createOrbit(radius: CGFloat(distanceFromSunInScene), colorHex: planet.planetColor)
                    parent.solarSystemNode.addChildNode(orbit)
                }
            }
            
            node.addChildNode(parent.solarSystemNode)
            solarSystemPlaced = true
        }


    }
}
// TODO: planet orbit not working
class ARPlanetCreator {
    func createOrbit(radius: CGFloat, colorHex: String) -> SCNNode {
        let orbit = SCNTorus(ringRadius: radius, pipeRadius: 0.002)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(hex: colorHex)
        orbit.materials = [material]
        
        let orbitNode = SCNNode(geometry: orbit)
        return orbitNode
    }
    
    func createARPlanet(name: String, data: [Planet]) -> SCNNode? {
        guard let planetInfo = data.first(where: { $0.name == name }) else { return nil }

        let diameter = CGFloat(planetInfo.diameter) / 1_000_000.0
        let planet = SCNSphere(radius: diameter / 2)
        
        let material = SCNMaterial()
        if let image = UIImage(named: name) {
            print("Loaded image for \(name)")
            material.diffuse.contents = image
        } else {
            print("Failed to load image for \(name)")
        }
        planet.materials = [material]

        let planetNode = SCNNode(geometry: planet)
        planetNode.name = name  // Assign the name for hit testing later

        // Create the text node for the planet name
        let text = SCNText(string: name, extrusionDepth: 0.02)
        text.font = UIFont(name: "Arial", size: 0.1)
        text.firstMaterial?.diffuse.contents = UIColor.white

        let textNode = SCNNode(geometry: text)
        // Adjust the position of the text node to appear above the planet
        textNode.position = SCNVector3(0, 0, 0)
        textNode.scale = SCNVector3(0.2, 0.2, 0.2) // Adjust the scale to appropriate size

        // Add the text node as a child of the planet node
        planetNode.addChildNode(textNode)
        
        return planetNode
    }

}

extension CGFloat {
    func toRadians() -> CGFloat {
        return self * .pi / 180.0
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        scanner.scanLocation = 1
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
