import SwiftUI
import CoreHaptics

struct MainContentView: View {
    @StateObject var viewModel = MainContentViewModel()
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
            Text("Select a Planet")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Choose a planet from the list below to proceed.")
                .font(.subheadline)
                .foregroundColor(.gray)
                
                List(viewModel.planets) { planet in
                    Button(action: {
                        toggleSelection(for: planet)
                    }) {
                        HStack {
                            // Display the planet image
                            Image("\(planet.name)Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding(.trailing, 10) // Add some spacing

                            // Display the planet name with increased font size and weight
                            Text(planet.name)
                                .font(.headline)

                            Spacer()

                            // Checkbox
                            Image(systemName: viewModel.selectedPlanets.contains(planet.id) ? "checkmark.square.fill" : "square")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .opacity(viewModel.selectedPlanets.contains(planet.id) ? 1.0 : 0.5)
                                .foregroundColor(viewModel.selectedPlanets.contains(planet.id) ? .blue : .gray)
                        }
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                }
                .listStyle(PlainListStyle())
                
                ZStack {
                    NavigationLink("", destination: ARPlaceView(selectedPlanets: Array(viewModel.selectedPlanets)), isActive: $viewModel.navigateToAR)

                    Button(action: viewModel.proceedButtonAction) {
                        Text("Proceed")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedPlanets.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                }
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text("Selection Required"),
                          message: Text("Please select a planet to proceed."),
                          dismissButton: .default(Text("Got it!")))
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .onAppear(perform: setDefaultSelectedPlanets)
        }
    }

    func setDefaultSelectedPlanets() {
        for planet in viewModel.planets {
            viewModel.selectedPlanets.insert(planet.id)
        }
    }

    func toggleSelection(for planet: Planet) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if viewModel.selectedPlanets.contains(planet.id) {
            viewModel.selectedPlanets.remove(planet.id)
        } else {
            viewModel.selectedPlanets.insert(planet.id)
        }
    }
}
