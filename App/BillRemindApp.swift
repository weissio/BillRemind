import SwiftUI
import SwiftData
import LocalAuthentication

@main
struct BillRemindApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode
    @State private var isUnlocked = false
    @State private var showingLockError = false

    private var sharedModelContainer: ModelContainer? = {
        let schema = Schema([
            Invoice.self,
            VendorProfile.self,
            OCRLearningProfile.self,
            IncomeEntry.self,
            InstallmentPlan.self,
            InstallmentSpecialRepayment.self,
            LearnedParsingRule.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            NSLog("Mnemor: persistent store initialization failed: \(error.localizedDescription)")
            return nil
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let sharedModelContainer {
                    ZStack {
                        HomeView()
                            .blur(radius: shouldShowLockOverlay ? 8 : 0)
                            .disabled(shouldShowLockOverlay)

                        if shouldShowLockOverlay {
                            VStack(spacing: 12) {
                                Text(appLanguageCode == "en" ? "App locked" : "App gesperrt")
                                    .font(.headline)
                                Button(appLanguageCode == "en" ? "Unlock" : "Entsperren") {
                                    authenticate()
                                }
                                .buttonStyle(.borderedProminent)
                                if showingLockError {
                                    Text(appLanguageCode == "en" ? "Authentication failed." : "Authentifizierung fehlgeschlagen.")
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
                    .modelContainer(sharedModelContainer)
                } else {
                    DataStoreErrorView()
                }
            }
            .tint(Color(red: 0.48, green: 0.31, blue: 0.22))
            .preferredColorScheme(.light)
            .environment(\.locale, Locale(identifier: appLanguageCode))
        }
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

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: appLanguageCode == "en" ? "Unlock Mnemor" : "Mnemor entsperren"
        ) { success, _ in
            DispatchQueue.main.async {
                isUnlocked = success
                showingLockError = !success
            }
        }
    }
}

private struct DataStoreErrorView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("Datenbankfehler", "Database error"))
                .font(.title2.weight(.semibold))
            Text(
                L10n.t(
                    "Die App konnte den lokalen Datenspeicher nicht laden. Zum Schutz deiner Daten wird die App nicht mit einem leeren Speicher gestartet.",
                    "The app could not load the local data store. To protect your data, the app will not start with an empty store."
                )
            )
            .font(.body)
            .foregroundStyle(.secondary)
            Text(
                L10n.t(
                    "Bitte App nicht deinstallieren. Starte das Gerät neu und versuche es erneut. Falls das Problem bleibt, melde dich über den Support.",
                    "Please do not uninstall the app. Restart your device and try again. If the issue persists, contact support."
                )
            )
            .font(.body)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
    }
}
