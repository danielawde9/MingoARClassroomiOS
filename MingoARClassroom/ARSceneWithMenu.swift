import SwiftUI

struct ARSceneWithMenu: View {
    var selectedPlanets: [String]
    
    @State private var isMenuShown = false
    private let rowHeight: CGFloat = 60
    private let menuHeight: CGFloat = 400
    
    var body: some View {
        ZStack {
            ARViewContainer(selectedPlanets: selectedPlanets)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isMenuShown.toggle()
                        }
                    }) {
                        Image(systemName: isMenuShown ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .padding(15)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
            }
            
            if isMenuShown {
                VisualEffectView(effect: UIBlurEffect(style: .dark))
                    .transition(.move(edge: .bottom))
                    .overlay(
                        ScrollView {
                            
                            VStack(spacing: 10) {
                                Text("Selected Planets")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
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
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                )
                            }
                            .padding()
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .padding(.horizontal, 15)
                    .frame(height: menuHeight)
            }
        }
    }
}
