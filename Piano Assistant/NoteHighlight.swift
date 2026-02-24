import SwiftUI

struct NoteHighlight: View {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat = 40
    var height: CGFloat = 40
    var color: Color 
    var opacity: Double = 0.5
    
    var body: some View {
        Circle()
            .fill(color)
            .opacity(opacity)
            .frame(width: width, height: height)
            .position(x: x, y: y) // x/y in window coordinates
        
    }
}
