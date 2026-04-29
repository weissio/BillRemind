import SwiftUI

struct FullScreenImageView: View {
    let image: UIImage?
    @Binding var isPresented: Bool
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode

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
                    Button(L10n.t("Schließen", "Close")) {
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}
