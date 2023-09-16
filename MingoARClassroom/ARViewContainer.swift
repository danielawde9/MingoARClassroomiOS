import SwiftUI
import ARKit

struct ARViewContainer: UIViewRepresentable {
    var selectedPlanets: [String]
    private var planetData: [Planet] = loadPlanetData()
    private let planetCreator = ARPlanetCreator()
    
    public init(selectedPlanets: [String]) {
        self.selectedPlanets = selectedPlanets
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        
        // Setup AR configuration with horizontal plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, planetCreator: planetCreator)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        var solarSystemPlaced = false  // Flag to ensure the solar system is placed only once
        var planetCreator: ARPlanetCreator
        
        init(_ parent: ARViewContainer, planetCreator: ARPlanetCreator) {
            self.parent = parent
            self.planetCreator = planetCreator
        }

        // This is called when a new plane (like the ground) is detected
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard !solarSystemPlaced, let planeAnchor = anchor as? ARPlaneAnchor else { return }

            let planets = parent.selectedPlanets.compactMap {
                planetCreator.createARPlanet(name: $0, data: parent.planetData)
            }

            var xOffset: Float = 0.15  // Initial offset
            for arPlanet in planets {
                arPlanet.position = SCNVector3(planeAnchor.center.x + xOffset, 0, planeAnchor.center.z)
                node.addChildNode(arPlanet)
                xOffset += Float(arPlanet.boundingSphere.radius * 2) + 0.15  // Increment the offset
            }
            
            solarSystemPlaced = true
        }
    }
}

// Separate class to handle AR planet creation
class ARPlanetCreator {
    func createARPlanet(name: String, data: [Planet]) -> SCNNode? {
        guard let planetInfo = data.first(where: { $0.name == name }) else { return nil }

        let diameter = CGFloat(planetInfo.diameter) / 1_000_000.0
        let planet = SCNSphere(radius: diameter / 2)
        
        // Fetch the texture from the PlanetMaterials folder
        let material = SCNMaterial()
        if let image = UIImage(named: name) {
            print("Loaded image for \(name)")

            material.diffuse.contents = image
        } else {
            print("Failed to load image for \(name)")

        }
        planet.materials = [material]

        return SCNNode(geometry: planet)
    }
}
