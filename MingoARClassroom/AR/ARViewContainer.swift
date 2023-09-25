import SwiftUI
import ARKit

struct ARViewContainer: UIViewRepresentable {
    var selectedPlanets: [String]
    private var planetData: [Planet] = loadPlanetData()
    var planetManager = PlanetManager()
    var arConfigurator = ARViewConfiguration()
    var gestureHandler = GestureHandler()
    
    var solarSystemNode: SCNNode = SCNNode()
    
    // Initializer for the struct
    public init(selectedPlanets: [String]) {
        self.selectedPlanets = selectedPlanets
    }
    
    // Configure and return the ARSCNView
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator

        arConfigurator.setupARConfiguration(for: arView)
        gestureHandler.setupGestureRecognizers(for: arView, with: context.coordinator)
        
        return arView
    }

    // Required method for UIViewRepresentable to update the ARSCNView's state
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    // Create and return the Coordinator class which will handle interactions with the ARSCNView
    func makeCoordinator() -> Coordinator {
        Coordinator(self, planetManager: planetManager)
    }
    

    
    // The Coordinator class acts as the bridge between SwiftUI and UIKit, handling interactions and updates.
    class Coordinator: NSObject, ARSCNViewDelegate {
        
        // Reference to the parent ARViewContainer to access its properties and methods.
        var parent: ARViewContainer
        
        // A boolean to track if the solar system has been placed in the AR scene.
        var solarSystemPlaced = false
        
        // An instance of planetManager to assist in creating and animating planets.
        var planetManager: PlanetManager
        
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
        init(_ parent: ARViewContainer, planetManager: PlanetManager) {
            self.parent = parent
            self.planetManager = planetManager
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
                if let planetNode = planetManager.createARPlanet(name: planet.name, data: planet) { // Pass single planet
                    
                    planetManager.applySelfRotation(planetNode: planetNode, planet: planet)
                    planetManager.animateRevolution(planetNode: planetNode, planet: planet)
                    
                    let orbit = planetManager.createOrbitForPlanet(planet: planet)
                    
                    planetNode.categoryBitMask = planetCategory
                    orbit.categoryBitMask = orbitCategory
                    
                    parent.solarSystemNode.addChildNode(planetNode)
                    parent.solarSystemNode.addChildNode(orbit)
                    
                }
            }
            // Add ambient light to the scene
            let ambientNode = planetManager.createAmbientLight()
            parent.solarSystemNode.addChildNode(ambientNode)
            
            node.addChildNode(parent.solarSystemNode)
            
            solarSystemPlaced = true
        }
    }
}



// MARK: - TODOS
// without dividing perihelion and perihelion and distanceFromSun, would be the true scale of the universe we cant see the planets, also sun scale
// planets name
// planet distance to sun
// show planet info on select
// arabic support
// planets if out of screen
// time
// sound
// contact , about, privacy version number
// ui helper
// ui sliders w hek
// when i click earth and scale make the earth middle of the screen to scale
