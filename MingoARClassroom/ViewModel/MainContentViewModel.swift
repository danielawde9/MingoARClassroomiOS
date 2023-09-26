//
//  MainContentViewModel.swift
//  MingoARClassroom
//
//  Created by Daniel Awde on 26/09/2023.
//

import Foundation

class MainContentViewModel: ObservableObject {
    let planets: [Planet] = loadPlanetData()
    @Published var selectedPlanets: Set<String> = []
    @Published var showAlert = false
    @Published var navigateToAR = false

    func proceedButtonAction() {
        if selectedPlanets.isEmpty {
            showAlert = true
        } else {
            navigateToAR = true
        }
    }
}
