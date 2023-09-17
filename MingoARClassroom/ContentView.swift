import SwiftUI
import CoreHaptics

struct ContentView: View {
    let planets: [Planet] = loadPlanetData()
    @State private var selectedPlanets: Set<String> = []
    @State private var showAlert = false
    @State private var navigateToAR = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Select a Planet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Subheading
                Text("Choose a planet from the list below to proceed.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                List(planets) { planet in
                    HStack {
                        // Display the planet image
                        Image("\(planet.name)Icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        
                        // Display the planet name
                        Text(planet.name)
                        
                        Spacer()
                        
                        // Checkbox
                        Image(systemName: selectedPlanets.contains(planet.id) ? "checkmark.square" : "square")
                            .opacity(selectedPlanets.contains(planet.id) ? 1.0 : 0.5)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        if selectedPlanets.contains(planet.id) {
                            selectedPlanets.remove(planet.id)
                        } else {
                            selectedPlanets.insert(planet.id)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .animation(.default, value: selectedPlanets)
                }
                .listStyle(PlainListStyle())

                ZStack {
                    NavigationLink("", destination: ARSceneWithMenu(selectedPlanets: Array(selectedPlanets))
                            .edgesIgnoringSafeArea(.all), isActive: $navigateToAR)
                            .opacity(0)
                            .frame(width: 0, height: 0)
                    
                    Button(action: proceedButtonAction) {
                        Text("Proceed")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(selectedPlanets.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    

                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Selection Required"),
                          message: Text("Please select a planet to proceed."),
                          dismissButton: .default(Text("Got it!")))
                }
            }
            .padding()
            .onAppear(perform: setDefaultSelectedPlanets) // Call the function when the view appears

        }
    }

    func proceedButtonAction() {
        withAnimation {
            if selectedPlanets.isEmpty {
                showAlert = true
            } else {
                navigateToAR = true
            }
        }
    }
    
    // This is the new function to set default selected planets
    func setDefaultSelectedPlanets() {
        for planet in planets {
            if planet.name != "Sun" {
                selectedPlanets.insert(planet.id)
            }
        }
    }
}
