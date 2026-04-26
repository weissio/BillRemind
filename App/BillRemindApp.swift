import SwiftUI
import SwiftData
import LocalAuthentication

extension Notification.Name {
    /// Wird gepostet, wenn die App per Share-Sheet / "Kopieren in Mnemor"
    /// eine PDF oder ein Bild von außen erhalten hat. userInfo enthält unter
    /// dem Schlüssel "url" eine stabile Kopie im temporären Verzeichnis.
    static let billRemindDidReceiveExternalDocument = Notification.Name("billRemindDidReceiveExternalDocument")
}

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
                                Text(L10n.t("App gesperrt", "App locked"))
                                    .font(.headline)
                                Button(L10n.t("Entsperren", "Unlock")) {
                                    authenticate()
                                }
                                .buttonStyle(.borderedProminent)
                                if showingLockError {
                                    Text(L10n.t("Authentifizierung fehlgeschlagen.", "Authentication failed."))
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
            .onOpenURL { url in
                handleExternalDocument(url: url)
            }
        }
    }

    /// Aufgerufen, wenn der Nutzer im Share-Sheet "Kopieren in Mnemor"
    /// (oder "In Mnemor öffnen") wählt — z. B. mit einer PDF aus Mail.
    /// Der eingehende URL ist potenziell security-scoped und wird daher
    /// in unseren tmp-Ordner kopiert; danach wandert er per Notification
    /// an HomeView/InvoicesScreen, die den Tab wechseln und das OCR
    /// anwerfen.
    private func handleExternalDocument(url: URL) {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess { url.stopAccessingSecurityScopedResource() }
        }

        let tmpDir = FileManager.default.temporaryDirectory
        let ext = url.pathExtension.isEmpty ? "tmp" : url.pathExtension
        let dest = tmpDir.appendingPathComponent("incoming-\(UUID().uuidString).\(ext)")
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: url, to: dest)
        } catch {
            NSLog("Mnemor: external document copy failed: \(error.localizedDescription)")
            return
        }

        NotificationCenter.default.post(
            name: .billRemindDidReceiveExternalDocument,
            object: nil,
            userInfo: ["url": dest]
        )
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
            localizedReason: L10n.t("Mnemor entsperren", "Unlock Mnemor")
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
