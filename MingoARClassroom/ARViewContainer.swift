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
        
        // Setup AR configuration with horizontal plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
        
        // Add pinch gesture recognizer
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, planetCreator: planetCreator)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        var solarSystemPlaced = false
        var planetCreator: ARPlanetCreator
        private var initialSolarSystemScale: SCNVector3 = SCNVector3(1, 1, 1)

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

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard !solarSystemPlaced, let planeAnchor = anchor as? ARPlaneAnchor else { return }

            let planets = parent.selectedPlanets.compactMap {
                planetCreator.createARPlanet(name: $0, data: parent.planetData)
            }

            var xOffset: Float = 0.15
            for arPlanet in planets {
                arPlanet.position = SCNVector3(planeAnchor.center.x + xOffset, 0, planeAnchor.center.z)
                parent.solarSystemNode.addChildNode(arPlanet)
                xOffset += Float(arPlanet.boundingSphere.radius * 2) + 0.15
            }
            
            node.addChildNode(parent.solarSystemNode)
            solarSystemPlaced = true
        }
    }
}

class ARPlanetCreator {
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

        return SCNNode(geometry: planet)
    }
}
