import SwiftUI

struct FullScreenImageView: View {
    let image: UIImage?
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") {
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}
