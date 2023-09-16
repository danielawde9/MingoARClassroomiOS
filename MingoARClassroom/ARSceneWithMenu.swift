import SwiftUI

struct ARSceneWithMenu: View {
    var selectedPlanets: [String]
    
    @State private var isMenuShown = false
    private let maxMenuHeight: CGFloat = 300  // Set max height
    
    var body: some View {
        ZStack {
            ARViewContainer(selectedPlanets: selectedPlanets)
            
            VStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        isMenuShown.toggle()
                    }
                }) {
                    Text(isMenuShown ? "chevron.up" : "chevron.down")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                }
                .padding(.bottom, 10)
                
                if isMenuShown {
                    VisualEffectView(effect: UIBlurEffect(style: .dark))
                        .clipShape(RoundedTopRectangle())
                        .transition(.move(edge: .bottom))
                        .overlay(
                            VStack {
                                Text("Selected Planets")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.top, 10)

                                List(selectedPlanets, id: \.self) { planet in
                                    Text(planet)
                                        .foregroundColor(.white)
                                        .font(.headline)
                                }
                                .listStyle(PlainListStyle())
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white)
                                )
                                .clipShape(RoundedTopRectangle())
                                .padding(.horizontal, 10)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: maxMenuHeight)  // Set max width and height
                }
            }
        }
    }
}

struct RoundedTopRectangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))  // bottom left
        path.addLine(to: CGPoint(x: 0, y: rect.minY + 20)) // top left with rounding
        path.addArc(center: CGPoint(x: 20, y: rect.minY + 20), radius: 20, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - 20, y: rect.minY))  // before top right rounding
        path.addArc(center: CGPoint(x: rect.maxX - 20, y: rect.minY + 20), radius: 20, startAngle: Angle(degrees: 270), endAngle: Angle(degrees: 360), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))  // bottom right
        return path
    }
}
