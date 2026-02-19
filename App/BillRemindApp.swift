import SwiftUI
import SwiftData
import LocalAuthentication

@main
struct BillRemindApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isUnlocked = false
    @State private var showingLockError = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Invoice.self, VendorProfile.self, IncomeEntry.self, InstallmentPlan.self, InstallmentSpecialRepayment.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .blur(radius: shouldShowLockOverlay ? 8 : 0)
                    .disabled(shouldShowLockOverlay)

                if shouldShowLockOverlay {
                    VStack(spacing: 12) {
                        Text("App gesperrt")
                            .font(.headline)
                        Button("Entsperren") {
                            authenticate()
                        }
                        .buttonStyle(.borderedProminent)
                        if showingLockError {
                            Text("Authentifizierung fehlgeschlagen.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .onAppear {
                if AppSettings.biometricLockEnabled {
                    authenticate()
                } else {
                    isUnlocked = true
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard AppSettings.biometricLockEnabled else {
                    isUnlocked = true
                    return
                }
                if newPhase == .active {
                    authenticate()
                } else if newPhase == .background {
                    isUnlocked = false
                }
            }
            .tint(Color(red: 0.48, green: 0.31, blue: 0.22))
            .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }

    private var shouldShowLockOverlay: Bool {
        AppSettings.biometricLockEnabled && !isUnlocked
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isUnlocked = true
            showingLockError = false
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "BillRemind entsperren") { success, _ in
            DispatchQueue.main.async {
                isUnlocked = success
                showingLockError = !success
            }
        }
    }
}
