//
//  ARViewConfiguration.swift
//  MingoARClassroom
//
//  Created by Daniel Awde on 25/09/2023.
//

import Foundation
import ARKit


class ARViewConfiguration {
    
    // Configure the AR session to detect horizontal planes
    func setupARConfiguration(for arView: ARSCNView) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
    }
}
