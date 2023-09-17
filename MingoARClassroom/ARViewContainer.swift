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
            
            for planet in parent.planetData where parent.selectedPlanets.contains(planet.name) {
                
               
            }
            
            node.addChildNode(parent.solarSystemNode)
            solarSystemPlaced = true
        }
    }
}

class ARPlanetCreator {
    var earthSelfRotationCount: Int = 0
    var earthRevolutionCount: Int = 0
    
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
    
    func createARPlanet(name: String, data: [Planet]) -> SCNNode? {
        guard let planetInfo = data.first(where: { $0.name == name }) else { return nil }

        // Convert planet's diameter to an appropriate scale for AR
        let diameter = CGFloat(planetInfo.diameter)
        let planet = SCNSphere(radius: diameter / 2)
        planet.segmentCount = 550
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: planetInfo.name)
        planet.materials = [material]
        
        let planetNode = SCNNode(geometry: planet)
        planetNode.name = planetInfo.name

        return planetNode
    }
}

extension Float {
    func toRadians() -> Float {
        return self * .pi / 180
    }
}
