import SwiftUI

struct ARPlaceView: View {
    var selectedPlanets: [String]
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isMenuShown = false
    @State private var sliderValue: Double = 0.5
    @State private var isToggleOn: Bool = true
    @State private var shouldNavigateBack: Bool = false
    
    private let rowHeight: CGFloat = 60
    private let navigationBarHeight: CGFloat = 0
    private let buttonSize: CGFloat = 50
    
    var body: some View {
        ZStack {
            ARViewContainer(selectedPlanets: selectedPlanets).ignoresSafeArea()
            
            NavigationLink("", destination: MainContentView().edgesIgnoringSafeArea(.all), isActive: $shouldNavigateBack)
                .opacity(0)
                .frame(width: 0, height: 0)
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .frame(width: buttonSize+20, height: buttonSize)
                            .background(Color.black.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10)))
                    }
                    .padding(.top, navigationBarHeight)
                    .padding(.leading, 20)
                    .navigationBarBackButtonHidden(true)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isMenuShown.toggle()
                        }
                    }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.white)
                            .font(.system(size: 24)) // Adjust the size of the image.
                            .frame(width: buttonSize+20, height: buttonSize) // Explicit frame for consistent size
                            .background(Color.black.opacity(0.5)) // A bit more transparency to make it more like Apple's design
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10))) // Makes the button round
                    }
                    .padding(.top, navigationBarHeight) // Adjust the top padding dynamically
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
        .navigationBarHidden(true) // Hide the navigation bar
        .statusBar(hidden: true) // Hide the status bar
        
        .navigationBarBackButtonHidden(true)  // This hides the default back button
        
    }
    
}
