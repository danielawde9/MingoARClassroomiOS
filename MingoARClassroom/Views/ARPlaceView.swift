import SwiftUI

struct ARPlaceView: View {
    var selectedPlanets: [String]
    
    @State private var isMenuShown = false
    @State private var sliderValue: Double = 0.5
    @State private var isToggleOn: Bool = true
    
    private let rowHeight: CGFloat = 60
    private let navigationBarHeight: CGFloat = 44
    private let buttonSize: CGFloat = 50
    
    var body: some View {
        ZStack {
            ARViewContainer(selectedPlanets: selectedPlanets)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isMenuShown.toggle()
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.white)
                            .font(.system(size: 24)) // Adjust the size of the image.
                            .frame(width: buttonSize, height: buttonSize) // Explicit frame for consistent size
                            .background(Color.black.opacity(0.5)) // A bit more transparency to make it more like Apple's design
                            .clipShape(Circle()) // Makes the button round
                    }
                    .padding(.top, navigationBarHeight - 15)
                    .padding(.trailing, 20)

                }
                Spacer()
            }

            if isMenuShown {
                VStack {
                    
                    Spacer()  // This will push the contents of the VStack downwards.
                    
                    VStack {
                        Capsule()
                            .frame(width: 40, height: 5)
                            .foregroundColor(.gray)
                            .padding(8)
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    isMenuShown = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                            }
                            .padding(.trailing, 20)
                        }
                        
                        Text("Selected Planets")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Slider(value: $sliderValue, in: 0...1)
                            .accentColor(.white)
                        
                        Toggle("Toggle Label", isOn: $isToggleOn)
                            .toggleStyle(SwitchToggleStyle())
                        
                        List(selectedPlanets, id: \.self) { planet in
                            HStack {
                                Image("\(planet)Icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                
                                Text(planet)
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .frame(height: rowHeight)
                        }
                        .listStyle(PlainListStyle())
                    }
                    .padding()
                    .background(Color.black.opacity(0.7).cornerRadius(25))
                    .transition(.move(edge: .bottom))
                    .frame(maxHeight: UIScreen.main.bounds.height / 2)
                }
            }
        }
    }
}
