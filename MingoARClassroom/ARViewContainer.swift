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
               
               if let tappedNode = hitResults.first?.node, parent.solarSystemNode.childNodes.contains(tappedNode) {
                   if tappedNode == selectedPlanetNode { // If the tapped planet is already selected
                       deselectPlanet(tappedNode)
                       selectedPlanetNode = nil
                   } else {
                       // Deselect the previous planet if one was selected
                       if let previouslySelected = selectedPlanetNode {
                           deselectPlanet(previouslySelected)
                       }

                       selectPlanet(tappedNode)
                       selectedPlanetNode = tappedNode
                   }
               }
           }

           func selectPlanet(_ node: SCNNode) {
               // Remove existing selection indicator if it exists
               node.childNode(withName: "selectionIndicator", recursively: false)?.removeFromParentNode()
               
               // Create a slightly larger sphere around the planet to indicate selection
               let selectionIndicator = SCNSphere(radius: CGFloat(node.boundingSphere.radius + 0.02))
               
               // Give it a semi-transparent blue material
               let material = SCNMaterial()
               material.diffuse.contents = UIColor.blue.withAlphaComponent(0.4) // Adjust alpha for desired transparency
               selectionIndicator.materials = [material]
               
               let selectionNode = SCNNode(geometry: selectionIndicator)
               selectionNode.name = "selectionIndicator"
               
               // Add the selection sphere as a child node to the planet so it moves with the planet
               node.addChildNode(selectionNode)

           }
        func deselectPlanet(_ node: SCNNode) {
            // Remove the selection indicator from the node
            node.childNode(withName: "selectionIndicator", recursively: false)?.removeFromParentNode()

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

        let planetNode = SCNNode(geometry: planet)

        // Create the text node for the planet name
        let text = SCNText(string: name, extrusionDepth: 0.02)
        text.font = UIFont(name: "Arial", size: 0.1)
        text.firstMaterial?.diffuse.contents = UIColor.white

        let textNode = SCNNode(geometry: text)
        // Adjust the position of the text node to appear above the planet
        textNode.position = SCNVector3(0, Float(diameter / 2) + 0.02, 0)
        textNode.scale = SCNVector3(0.2, 0.2, 0.2) // Adjust the scale to appropriate size

        // Add the text node as a child of the planet node
        planetNode.addChildNode(textNode)

        return planetNode
    }
}
