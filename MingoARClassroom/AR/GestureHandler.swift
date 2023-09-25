import ARKit
import UIKit

class GestureHandler {
    
    // This method sets up gesture recognizers for the given ARSCNView
    func setupGestureRecognizers(for arView: ARSCNView, with coordinator: ARViewContainer.Coordinator) {
        setupPinchGesture(for: arView, with: coordinator)
        setupTapGesture(for: arView, with: coordinator)
    }
    
    private func setupPinchGesture(for arView: ARSCNView, with context: ARViewContainer.Coordinator) {
        let pinchGesture = UIPinchGestureRecognizer(target: context, action: #selector(ARViewContainer.Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
    }
    
    private func setupTapGesture(for arView: ARSCNView, with context: ARViewContainer.Coordinator) {
        let tapGesture = UITapGestureRecognizer(target: context, action: #selector(ARViewContainer.Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
}
