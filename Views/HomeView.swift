import SwiftUI
import SwiftData
import Charts
import UniformTypeIdentifiers
import UIKit

struct HomeView: View {
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            InvoicesScreen()
                .tabItem {
                    Label(isEnglish ? "Invoices" : "Rechnungen", systemImage: "house.fill")
                }
                .tag(0)

            NavigationStack {
                StatsView(mode: .expenses)
            }
            .tabItem {
                Label(isEnglish ? "Expenses" : "Ausgaben", systemImage: "chart.pie.fill")
            }
            .tag(1)

            NavigationStack {
                IncomeManagementView()
            }
            .tabItem {
                Label(isEnglish ? "Income" : "Einnahmen", systemImage: "eurosign.circle.fill")
            }
            .tag(2)

            NavigationStack {
                StatsView(mode: .reports)
            }
            .tabItem {
                Label(isEnglish ? "Analytics" : "Auswertung", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(3)

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label(isEnglish ? "More" : "Mehr", systemImage: "square.grid.2x2.fill")
            }
            .tag(4)
        }
        .tint(Color(red: 0.31, green: 0.42, blue: 0.56))
        .onReceive(NotificationCenter.default.publisher(for: .billRemindDidReceiveExternalDocument)) { _ in
            // Aktiver Tab-Wechsel auf Rechnungen, sobald von außen eine
            // PDF/ein Bild geteilt wurde — InvoicesScreen kümmert sich um
            // OCR und das Review-Sheet.
            selectedTab = 0
        }
    }

    private var isEnglish: Bool {
        appLanguageCode == "en"
    }
}

private struct MoreView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode
    @State private var supportInfoMessage: String?

    var body: some View {
        List {
            Section {
                NavigationLink(isEnglish ? "Guide" : "Anleitung") {
                    HelpView()
                }
                NavigationLink("Settings") {
                    SettingsView()
                }
                NavigationLink(isEnglish ? "Feedback" : "Feedback") {
                    FeedbackView()
                }
            }
            Section {
                Button(L10n.t("Problem melden", "Report issue")) {
                    openBugReportMail()
                }
                Button(L10n.t("Debug-Infos kopieren", "Copy debug info")) {
                    copyDebugInfo()
                }
            }
        }
        .navigationTitle(isEnglish ? "More" : "Mehr")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            L10n.t("Hinweis", "Info"),
            isPresented: Binding(
                get: { supportInfoMessage != nil },
                set: { newValue in
                    if !newValue { supportInfoMessage = nil }
                }
            ),
            actions: {
                Button(L10n.t("OK", "OK"), role: .cancel) {}
            },
            message: {
                Text(supportInfoMessage ?? "")
            }
        )
    }

    private var isEnglish: Bool {
        appLanguageCode == "en"
    }

    private func openBugReportMail() {
        guard let url = SupportMailService.bugReportURL(
            isEnglish: isEnglish,
            source: "MoreMenu"
        ) else {
            supportInfoMessage = L10n.t(
                "Bug-Mail konnte nicht vorbereitet werden.",
                "Could not prepare bug email."
            )
            return
        }
        openURL(url)
    }

    private func copyDebugInfo() {
        UIPasteboard.general.string = SupportMailService.debugInfoText(source: "MoreMenu")
        supportInfoMessage = L10n.t("Debug-Infos kopiert.", "Debug info copied.")
    }
}

private struct InvoicesScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var invoices: [Invoice]
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var scanViewModel = ScanViewModel()
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode

    @State private var showScanner = false
    @State private var showReview = false
    @State private var showPDFImporter = false
    @State private var scanCaptureMode: ScanCaptureMode = .invoice
    @State private var dueWindowDays: Int = 7
    @State private var paidWindowDays: Int = 7

    private static let dueWindowOptions: [Int] = [7, 14, 30, 60, 90]
    // Paid hat zusätzlich 180/360 Tage für Halbjahres-/Jahresreview.
    // Sobald die App ein zweites Jahr läuft, kann hier ggf. eine
    // monatliche Cluster-Ansicht ergänzt werden (z. B. bei Paid und All).
    private static let paidWindowOptions: [Int] = [7, 14, 30, 60, 90, 180, 360]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppHeroHeader(
                    title: isEnglish ? "Invoices" : "Rechnungen",
                    subtitle: isEnglish ? "Scan, organize, pay" : "Scannen, ordnen, bezahlen",
                    icon: "tray.full.fill"
                ) {
                    // Menü statt confirmationDialog: das Popover ankert direkt
                    // unter dem +-Tile, statt iOS-typisch unten am Bildschirm
                    // aufzuklappen — kürzerer Weg vom Antippen zur Auswahl.
                    Menu {
                        Button {
                            scanCaptureMode = .invoice
                            showScanner = true
                        } label: {
                            Label(isEnglish ? "Scan invoice" : "Scan Rechnung", systemImage: "doc.text.viewfinder")
                        }
                        Button {
                            scanCaptureMode = .receipt
                            showScanner = true
                        } label: {
                            Label(isEnglish ? "Scan receipt" : "Scan Kassenbon", systemImage: "scroll")
                        }
                        Button {
                            scanViewModel.prepareManualEntry()
                            showReview = true
                        } label: {
                            Label(isEnglish ? "Manual entry" : "Manuell erfassen", systemImage: "square.and.pencil")
                        }
                        Button {
                            showPDFImporter = true
                        } label: {
                            Label(isEnglish ? "Import PDF" : "PDF Import", systemImage: "doc.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .accessibilityLabel(isEnglish ? "Add invoice" : "Rechnung hinzufügen")
                }

                VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        dashboardDueCard()
                        dashboardCard(
                            title: isEnglish ? "Overdue" : "Überfällig",
                            value: "\(overdueCount)",
                            subValue: overdueAmount.formatted(.currency(code: "EUR")),
                            symbol: "exclamationmark.triangle.fill",
                            tint: .red
                        )
                        dashboardPaidCard()
                    }
                    .padding(.horizontal)
                }

                Picker("Filter", selection: $viewModel.filter) {
                    ForEach(InvoiceFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                let filtered = viewModel.filtered(invoices)
                if filtered.isEmpty {
                    ContentUnavailableView(
                        isEnglish ? "No invoices yet" : "Noch keine Rechnungen",
                        systemImage: "doc.text.viewfinder",
                        description: Text(isEnglish ? "Tap Scan, take a photo of an invoice, and review the detected fields." : "Tippe auf Scannen, fotografiere eine Rechnung und prüfe die erkannten Felder.")
                    )
                } else if viewModel.filter == .open {
                    // Open bleibt bewusst flach — hier zählt die Reihenfolge nach
                    // Eingang/Fälligkeit, nicht eine Monatsgliederung.
                    List(filtered) { invoice in
                        let isDuplicate = duplicateInvoiceIDs.contains(invoice.id)
                        NavigationLink {
                            InvoiceDetailView(invoice: invoice)
                        } label: {
                            InvoiceRowView(invoice: invoice, isLikelyDuplicate: isDuplicate)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .listRowSpacing(8)
                } else {
                    // Paid und All: nach Monat gruppieren. Bei Paid steht
                    // pro Section, was in dem Monat bezahlt wurde; bei All
                    // wird zusätzlich anhand invoiceDate eingeordnet, damit
                    // offene Rechnungen ebenfalls einen Monat bekommen.
                    List {
                        ForEach(monthlyInvoiceGroups(filtered)) { group in
                            Section {
                                ForEach(group.invoices) { invoice in
                                    let isDuplicate = duplicateInvoiceIDs.contains(invoice.id)
                                    NavigationLink {
                                        InvoiceDetailView(invoice: invoice)
                                    } label: {
                                        InvoiceRowView(invoice: invoice, isLikelyDuplicate: isDuplicate)
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                }
                            } header: {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(group.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.accent)
                                    Spacer()
                                    Text("\(group.invoices.count) · \(group.amount.formatted(.currency(code: "EUR")))")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                                .padding(.vertical, 4)
                                .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .listRowSpacing(8)
                }
                }
            }
            .background(warmBackground.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.accent)
            .sheet(isPresented: $showScanner) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    CameraPicker { image in
                        Task {
                            await scanViewModel.processPickedImage(image, mode: scanCaptureMode)
                            showScanner = false
                            showReview = true
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    ContentUnavailableView(isEnglish ? "Camera unavailable" : "Kamera nicht verfügbar", systemImage: "camera.fill")
                }
            }
            .sheet(isPresented: $showReview) {
                ReviewInvoiceView(scanViewModel: scanViewModel) {
                    showReview = false
                }
            }
            .fileImporter(
                isPresented: $showPDFImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    Task {
                        let hasAccess = url.startAccessingSecurityScopedResource()
                        defer {
                            if hasAccess { url.stopAccessingSecurityScopedResource() }
                        }
                        await scanViewModel.processPDF(at: url)
                        showReview = true
                    }
                case .failure:
                    break
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .billRemindDidReceiveExternalDocument)) { notification in
                guard let url = notification.userInfo?["url"] as? URL else { return }
                Task {
                    await handleIncomingExternalDocument(url: url)
                }
            }
        }
    }

    /// Verarbeitet ein per Share-Sheet eingegangenes Dokument: PDFs gehen in
    /// den PDF-Pfad, Bilder durch die OCR-Pipeline. In beiden Fällen öffnet
    /// sich danach das Review-Sheet wie bei manuellem Scan/Import.
    private func handleIncomingExternalDocument(url: URL) async {
        defer {
            // tmp-Datei aufräumen — der Importer hat Bild bzw. OCR-Text
            // bereits in den Speicher gezogen.
            try? FileManager.default.removeItem(at: url)
        }

        let ext = url.pathExtension.lowercased()
        if ext == "pdf" {
            await scanViewModel.processPDF(at: url)
            showReview = true
            return
        }

        if let image = UIImage(contentsOfFile: url.path) {
            await scanViewModel.processPickedImage(image, mode: .invoice)
            showReview = true
            return
        }

        // Unbekannter Typ — als Notausgang das manuelle Erfassungs-Sheet.
        scanViewModel.prepareManualEntry()
        showReview = true
    }

    private var isEnglish: Bool {
        appLanguageCode == "en"
    }

    private var warmBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.94, green: 0.95, blue: 0.97), Color(red: 0.91, green: 0.93, blue: 0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func dueInNextDaysInvoices(_ days: Int) -> [Invoice] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: days, to: start) ?? start
        return invoices.filter { invoice in
            guard invoice.status == .open, let due = invoice.dueDate else { return false }
            let day = Calendar.current.startOfDay(for: due)
            return day >= start && day <= end
        }
    }

    private func dueInNextDaysCount(_ days: Int) -> Int {
        dueInNextDaysInvoices(days).count
    }

    private func dueInNextDaysAmount(_ days: Int) -> Decimal {
        dueInNextDaysInvoices(days).reduce(Decimal(0)) { partial, invoice in
            partial + (invoice.amount ?? 0)
        }
    }

    private func dueWindowLabel(days: Int) -> String {
        isEnglish ? "Due in \(days) days" : "Fällig in \(days) Tagen"
    }

    private var overdueInvoices: [Invoice] {
        let today = Calendar.current.startOfDay(for: Date())
        return invoices.filter { invoice in
            guard invoice.status == .open, let due = invoice.dueDate else { return false }
            return Calendar.current.startOfDay(for: due) < today
        }
    }

    private var overdueCount: Int {
        overdueInvoices.count
    }

    private var overdueAmount: Decimal {
        overdueInvoices.reduce(Decimal(0)) { partial, invoice in
            partial + (invoice.amount ?? 0)
        }
    }

    private func paidInLastDaysInvoices(_ days: Int) -> [Invoice] {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -days, to: today) ?? today
        return invoices.filter { invoice in
            guard invoice.status == .paid, let paid = invoice.paidAt else { return false }
            let day = Calendar.current.startOfDay(for: paid)
            return day >= start && day <= today
        }
    }

    private func paidInLastDaysCount(_ days: Int) -> Int {
        paidInLastDaysInvoices(days).count
    }

    private func paidInLastDaysAmount(_ days: Int) -> Decimal {
        paidInLastDaysInvoices(days).reduce(Decimal(0)) { partial, invoice in
            partial + (invoice.amount ?? 0)
        }
    }

    private func paidWindowLabel(days: Int) -> String {
        isEnglish ? "Paid last \(days) days" : "Bezahlt letzte \(days) Tage"
    }

    private struct MonthlyInvoiceGroup: Identifiable {
        let id: Date          // Monatsanfang, dient gleichzeitig als Sortier­schlüssel
        let title: String
        let invoices: [Invoice]
        let amount: Decimal
    }

    /// Gruppiert eine Rechnungsliste nach Monat. Für bezahlte Rechnungen wird
    /// der Bezahltag verwendet (so steht eine Rechnung in dem Monat, in dem
    /// sie bezahlt wurde), für offene Rechnungen das Rechnungsdatum bzw. der
    /// Erfassungszeitpunkt als Fallback. Reihenfolge: neueste Monate oben.
    private func monthlyInvoiceGroups(_ invoices: [Invoice]) -> [MonthlyInvoiceGroup] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: isEnglish ? "en_US" : "de_DE")
        formatter.dateFormat = "LLLL yyyy"

        func referenceDate(for invoice: Invoice) -> Date {
            invoice.paidAt ?? invoice.invoiceDate ?? invoice.createdAt
        }

        let grouped = Dictionary(grouping: invoices) { invoice -> Date in
            let date = referenceDate(for: invoice)
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? date
        }

        return grouped.map { (monthStart, items) in
            let sorted = items.sorted { referenceDate(for: $0) > referenceDate(for: $1) }
            let total = sorted.reduce(Decimal(0)) { partial, invoice in
                partial + (invoice.amount ?? 0)
            }
            let title = formatter.string(from: monthStart)
            return MonthlyInvoiceGroup(id: monthStart, title: title, invoices: sorted, amount: total)
        }
        .sorted { $0.id > $1.id }
    }

    private var duplicateInvoiceIDs: Set<UUID> {
        var groups: [String: [UUID]] = [:]
        for invoice in invoices {
            let vendor = invoice.vendorName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .decomposedStringWithCanonicalMapping
                .lowercased()
            let number = (invoice.invoiceNumber ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .decomposedStringWithCanonicalMapping
                .lowercased()
            let amount = invoice.amount.map { NSDecimalNumber(decimal: $0).stringValue } ?? "-"
            let key: String
            if !number.isEmpty {
                key = "nr:\(number)|amt:\(amount)|vendor:\(vendor)"
            } else {
                key = "amt:\(amount)|vendor:\(vendor)"
            }
            groups[key, default: []].append(invoice.id)
        }

        var duplicates = Set<UUID>()
        for ids in groups.values where ids.count > 1 {
            duplicates.formUnion(ids)
        }
        return duplicates
    }

    private func dashboardCard(title: String, value: String, subValue: String? = nil, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.23, green: 0.35, blue: 0.50))
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color(red: 0.34, green: 0.43, blue: 0.54))
                .lineLimit(2)
            Text(value)
                .font(.headline)
                .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.24))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let subValue, !subValue.isEmpty {
                Text(subValue)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color(red: 0.34, green: 0.43, blue: 0.54))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .monospacedDigit()
            }
        }
        .frame(width: 195, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.82, green: 0.86, blue: 0.91), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func dashboardDueCard() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "calendar.badge.clock")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.23, green: 0.35, blue: 0.50))
            Menu {
                ForEach(Self.dueWindowOptions, id: \.self) { days in
                    Button {
                        dueWindowDays = days
                    } label: {
                        if days == dueWindowDays {
                            Label(dueWindowLabel(days: days), systemImage: "checkmark")
                        } else {
                            Text(dueWindowLabel(days: days))
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(dueWindowLabel(days: dueWindowDays))
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.34, green: 0.43, blue: 0.54))
                        .lineLimit(2)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(red: 0.34, green: 0.43, blue: 0.54))
                }
            }
            .buttonStyle(.plain)
            Text("\(dueInNextDaysCount(dueWindowDays))")
                .font(.headline)
                .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.24))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(dueInNextDaysAmount(dueWindowDays).formatted(.currency(code: "EUR")))
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color(red: 0.34, green: 0.43, blue: 0.54))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
        }
        .frame(width: 195, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.82, green: 0.86, blue: 0.91), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func dashboardPaidCard() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.23, green: 0.35, blue: 0.50))
            Menu {
                ForEach(Self.paidWindowOptions, id: \.self) { days in
                    Button {
                        paidWindowDays = days
                    } label: {
                        if days == paidWindowDays {
                            Label(paidWindowLabel(days: days), systemImage: "checkmark")
                        } else {
                            Text(paidWindowLabel(days: days))
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(paidWindowLabel(days: paidWindowDays))
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.34, green: 0.43, blue: 0.54))
                        .lineLimit(2)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(red: 0.34, green: 0.43, blue: 0.54))
                }
            }
            .buttonStyle(.plain)
            Text("\(paidInLastDaysCount(paidWindowDays))")
                .font(.headline)
                .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.24))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(paidInLastDaysAmount(paidWindowDays).formatted(.currency(code: "EUR")))
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color(red: 0.34, green: 0.43, blue: 0.54))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
        }
        .frame(width: 195, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.82, green: 0.86, blue: 0.91), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

private struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    enum Mode {
        case expenses
        case reports
    }

    enum DataScope: CaseIterable, Identifiable {
        case open
        case all

        var id: String { title }

        var title: String {
            switch self {
            case .open: return L10n.t("Nur offen", "Open only")
            case .all: return L10n.t("Alle", "All")
            }
        }
    }

    enum StatsTab: CaseIterable, Identifiable {
        case analysis
        case fixedCosts

        var id: String { title }

        var title: String {
            switch self {
            case .analysis: return L10n.t("Übersicht", "Overview")
            case .fixedCosts: return L10n.t("Fixkosten", "Fixed costs")
            }
        }
    }

    enum ReportsTab: CaseIterable, Identifiable {
        case total
        case invoices

        var id: String { title }

        var title: String {
            switch self {
            case .total: return L10n.t("Gesamt", "Total")
            case .invoices: return L10n.t("Rechnungen", "Invoices")
            }
        }
    }

    enum ReportInvoiceStatusScope: CaseIterable, Identifiable {
        case open
        case paid
        case all

        var id: String { title }

        var title: String {
            switch self {
            case .open: return L10n.t("Offen", "Open")
            case .paid: return L10n.t("Bezahlt", "Paid")
            case .all: return L10n.t("Alle", "All")
            }
        }
    }

    @Query private var invoices: [Invoice]
    @Query private var incomeEntries: [IncomeEntry]
    @Query private var installmentPlans: [InstallmentPlan]
    @Query private var specialRepayments: [InstallmentSpecialRepayment]
    @State private var mode: Mode = .reports
    @State private var selectedTab: StatsTab = .analysis
    @State private var selectedReportsTab: ReportsTab = .total
    @State private var selectedMonth: Date = Date()
    @State private var dataScope: DataScope = .open
    @State private var reportInvoiceStatusScope: ReportInvoiceStatusScope = .all
    // Observed so the view re-renders when the language is toggled in Settings
    // (otherwise enum-driven Picker labels stay stuck in the previous language).
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode
    @AppStorage(AppSettings.exportFormatKey) private var exportFormat: String = AppSettings.exportFormat
    @AppStorage("liquidity.startBalance") private var startBalance: Double = 0
    @AppStorage("liquidity.useCurrentBalance") private var useCurrentBalance: Bool = false
    @AppStorage("liquidity.currentBalance") private var currentBalance: Double = 0
    @AppStorage(AppSettings.negativeCashflowAlertEnabledKey) private var negativeCashflowAlertEnabled: Bool = AppSettings.negativeCashflowAlertEnabled
    @AppStorage(AppSettings.negativeCashflowAlertWeeksKey) private var negativeCashflowAlertWeeks: Int = AppSettings.negativeCashflowAlertWeeks
    @State private var exportURL: URL?
    @State private var exportStatusMessage: String?
    @State private var installmentName: String = ""
    @State private var installmentKind: InstallmentPlan.Kind = .fixedCost
    @State private var installmentLoanRepaymentMode: InstallmentPlan.LoanRepaymentMode = .annuity
    @State private var installmentMonthlyPayment: Decimal?
    @State private var installmentMonthlyInterest: Decimal?
    @State private var installmentAnnualInterestRate: Decimal?
    @State private var installmentInitialPrincipal: Decimal?
    @State private var installmentStartDate: Date = Date()
    @State private var installmentHasEndDate: Bool = false
    @State private var installmentEndDate: Date = Date()
    @State private var installmentPaymentDay: Int = 1
    @State private var installmentValidationMessage: String?
    @State private var editingInstallmentPlan: InstallmentPlan?
    @State private var isShowingEditInstallmentSheet = false
    @State private var editInstallmentName: String = ""
    @State private var editInstallmentKind: InstallmentPlan.Kind = .fixedCost
    @State private var editInstallmentLoanRepaymentMode: InstallmentPlan.LoanRepaymentMode = .annuity
    @State private var editInstallmentMonthlyPayment: Decimal?
    @State private var editInstallmentMonthlyInterest: Decimal?
    @State private var editInstallmentAnnualInterestRate: Decimal?
    @State private var editInstallmentInitialPrincipal: Decimal?
    @State private var editInstallmentStartDate: Date = Date()
    @State private var editInstallmentHasEndDate: Bool = false
    @State private var editInstallmentEndDate: Date = Date()
    @State private var editInstallmentPaymentDay: Int = 1
    @State private var editInstallmentValidationMessage: String?
    @State private var editContextKind: InstallmentPlan.Kind = .fixedCost
    @State private var editSpecialRepaymentAmountText: String = ""
    @State private var editSpecialRepaymentDate: Date = Date()
    @State private var specialRepaymentPlanForSheet: InstallmentPlan?
    @State private var planningWeeks: Int = 12
    @State private var selectedWeekStart: Date?
    @FocusState private var isAmountFieldFocused: Bool
    private let notificationService = NotificationService()

    private let calendar = Calendar.current

    init(mode: Mode = .reports) {
        _mode = State(initialValue: mode)
        if mode == .expenses {
            _selectedTab = State(initialValue: .analysis)
        } else {
            _selectedTab = State(initialValue: .analysis)
            _selectedReportsTab = State(initialValue: .total)
        }
    }

    private var editingKind: InstallmentPlan.Kind {
        editContextKind
    }

    private var isEditingLoan: Bool {
        editingKind == .loan
    }

    @ViewBuilder
    private var topSegmentBar: some View {
        HStack(spacing: 8) {
            if mode == .expenses {
                ForEach(StatsTab.allCases) { tab in
                    segmentButton(
                        title: tab.title,
                        icon: iconName(for: tab),
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            } else {
                ForEach(ReportsTab.allCases) { tab in
                    segmentButton(
                        title: tab.title,
                        icon: iconName(for: tab),
                        isSelected: selectedReportsTab == tab
                    ) {
                        selectedReportsTab = tab
                    }
                }
            }
        }
    }

    private func segmentButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let accent = AppTheme.accent
        return Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.18) : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? accent.opacity(0.45) : Color.clear, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? accent : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private func iconName(for tab: StatsTab) -> String {
        switch tab {
        case .analysis: return "chart.bar.fill"
        case .fixedCosts: return "calendar.badge.clock"
        }
    }

    private func iconName(for tab: ReportsTab) -> String {
        switch tab {
        case .total: return "chart.line.uptrend.xyaxis"
        case .invoices: return "doc.text.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeroHeader(
                title: mode == .expenses
                    ? L10n.t("Ausgaben", "Expenses")
                    : L10n.t("Auswertung", "Analytics"),
                subtitle: mode == .expenses
                    ? L10n.t("Kosten und Fixkosten im Überblick", "Costs and fixed costs at a glance")
                    : L10n.t("Einnahmen, Ausgaben und Saldo", "Income, expenses and balance"),
                icon: mode == .expenses
                    ? "creditcard.fill"
                    : "chart.bar.doc.horizontal.fill"
            )

            topSegmentBar
                .padding(.horizontal, 16)
                .padding(.top, 2)
                .padding(.bottom, 6)

            Form {
            if !(mode == .expenses && selectedTab == .fixedCosts) {
                Section {
                    Picker(L10n.t("Monat", "Month"), selection: $selectedMonth) {
                        ForEach(availableMonths, id: \.self) { month in
                            Text(monthLabel(for: month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)

                    if mode == .expenses {
                        Picker(L10n.t("Datenbasis", "Data scope"), selection: $dataScope) {
                            ForEach(DataScope.allCases) { scope in
                                Text(scope.title).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else if selectedReportsTab == .invoices {
                        Picker(L10n.t("Status", "Status"), selection: $reportInvoiceStatusScope) {
                            ForEach(ReportInvoiceStatusScope.allCases) { scope in
                                Text(scope.title).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }

            if (mode == .expenses && selectedTab == .analysis) || (mode == .reports && selectedReportsTab == .total) {
                Section {
                    if mode == .expenses {
                        if dataScope == .open {
                            metricsCard(rows: [
                                (L10n.t("Anzahl Rechnungen", "Number of invoices"), "\(monthlyOpenInvoiceCount)", true),
                                (L10n.t("Betrag Rechnungen", "Invoice amount"), monthlyOpenInvoiceAmount.formatted(.currency(code: "EUR")), true),
                                (L10n.t("Fixkosten offen", "Open fixed costs"), monthlyOpenFixedCostAmount.formatted(.currency(code: "EUR")), false),
                                (L10n.t("Gesamt offen", "Open total"), monthlyTotalOpenAmount.formatted(.currency(code: "EUR")), true),
                            ])
                        } else {
                            metricsCard(rows: [
                                (L10n.t("Anzahl Rechnungen", "Number of invoices"), "\(monthlyInvoiceCountAll)", true),
                                (L10n.t("Betrag Rechnungen", "Invoice amount"), monthlyInvoiceAmountAll.formatted(.currency(code: "EUR")), true),
                                (L10n.t("Davon offen", "Open part"), "\(monthlyOpenInvoiceCount) · \(monthlyOpenInvoiceAmount.formatted(.currency(code: "EUR")))", false),
                                (L10n.t("Davon bezahlt", "Paid part"), "\(monthlyPaidInvoiceCount) · \(monthlyPaidInvoiceAmount.formatted(.currency(code: "EUR")))", false),
                                (L10n.t("Fixkosten offen", "Open fixed costs"), "\(monthlyOpenFixedCostCount) · \(monthlyOpenFixedCostAmount.formatted(.currency(code: "EUR")))", false),
                                (L10n.t("Fixkosten bezahlt", "Paid fixed costs"), "\(monthlyPaidFixedCostCount) · \(monthlyPaidFixedCostAmount.formatted(.currency(code: "EUR")))", false),
                                (L10n.t("Gesamt offen", "Open total"), monthlyTotalOpenAmount.formatted(.currency(code: "EUR")), false),
                                (L10n.t("Gesamt bezahlt", "Paid total"), monthlyTotalPaidAmount.formatted(.currency(code: "EUR")), false),
                                (L10n.t("Gesamt", "Total"), monthlyTotalAmount.formatted(.currency(code: "EUR")), true),
                            ])
                        }
                    } else {
                        metricsCard(rows: [
                            (L10n.t("Einnahmen", "Income"), reportActualIncome.formatted(.currency(code: "EUR")), true),
                            (L10n.t("Ausgaben", "Expenses"), reportActualExpenses.formatted(.currency(code: "EUR")), true),
                            (L10n.t("Differenz", "Difference"), reportActualDifference.formatted(.currency(code: "EUR")), true),
                            (L10n.t("Noch fällig Einnahmen", "Pending income"), reportPendingIncome.formatted(.currency(code: "EUR")), false),
                            (L10n.t("Noch fällig Ausgaben", "Pending expenses"), reportPendingExpenses.formatted(.currency(code: "EUR")), false),
                            (L10n.t("Noch fällige Differenz", "Pending difference"), reportPendingDifference.formatted(.currency(code: "EUR")), false),
                            (L10n.t("Differenz Monatsende", "Month-end difference"), reportPlannedMonthEndDifference.formatted(.currency(code: "EUR")), true),
                        ])
                    }
                } header: {
                    HStack {
                        Text(L10n.t("Übersicht", "Overview"))
                        Spacer()
                        if mode == .reports {
                            Text("\(L10n.t("Stand", "As of")) \(reportAsOfDateText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                reportsPlanningSections
            }

            reportsInvoiceSections

            fixedCostSections
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .tint(AppTheme.accent)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.t("Fertig", "Done")) {
                    isAmountFieldFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .onAppear {
            normalizeInstallmentTypeFlagsIfNeeded()
            if let first = availableMonths.first {
                selectedMonth = first
            } else {
                selectedMonth = startOfMonth(for: Date())
            }
        }
        .task(id: weeklyPlanRowsSignature) {
            await updateNegativeCashflowAlertIfNeeded()
        }
        .sheet(isPresented: $isShowingEditInstallmentSheet) {
            NavigationStack {
                Form {
                    Section(L10n.t("Details", "Details")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.t("Bezeichnung", "Name"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("z. B. Auto Leasing", text: $editInstallmentName)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                isEditingLoan && editInstallmentLoanRepaymentMode == .fixedPrincipal
                                    ? L10n.t("Monatliche Tilgung", "Monthly principal")
                                    : L10n.t("Monatliche Rate", "Monthly payment")
                            )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("z. B. 420,00", value: $editInstallmentMonthlyPayment, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                                .focused($isAmountFieldFocused)
                        }
                        HStack {
                            Text(L10n.t("Typ", "Type"))
                            Spacer()
                            Text(editingKind.title)
                                .foregroundStyle(.secondary)
                        }

                        DatePicker(L10n.t("Startdatum", "Start date"), selection: $editInstallmentStartDate, displayedComponents: .date)
                        Stepper("\(L10n.t("Fälligkeitstag", "Due day")): \(editInstallmentPaymentDay).", value: $editInstallmentPaymentDay, in: 1...28)
                        Toggle(L10n.t("Enddatum setzen", "Set end date"), isOn: $editInstallmentHasEndDate)
                        if editInstallmentHasEndDate {
                            DatePicker(L10n.t("Enddatum", "End date"), selection: $editInstallmentEndDate, displayedComponents: .date)
                        }
                        if let editInstallmentValidationMessage {
                            Text(editInstallmentValidationMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    if isEditingLoan {
                        Section(L10n.t("Kreditdetails", "Loan details")) {
                            Picker(L10n.t("Kreditart", "Loan type"), selection: $editInstallmentLoanRepaymentMode) {
                                ForEach(InstallmentPlan.LoanRepaymentMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            if editInstallmentLoanRepaymentMode == .fixedPrincipal {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(L10n.t("Sollzins p.a. (%)", "Nominal interest p.a. (%)"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("z. B. 5,49", value: $editInstallmentAnnualInterestRate, format: .number.precision(.fractionLength(3)))
                                        .keyboardType(.decimalPad)
                                        .focused($isAmountFieldFocused)
                                    Text(L10n.t("Pflichtfeld bei fester Tilgung.", "Required for fixed principal mode."))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(L10n.t("Sollzins p.a. (%)", "Nominal interest p.a. (%)"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("optional, z. B. 5,49", value: $editInstallmentAnnualInterestRate, format: .number.precision(.fractionLength(3)))
                                        .keyboardType(.decimalPad)
                                        .focused($isAmountFieldFocused)
                                    Text(L10n.t("Für Restschuld-Berechnung empfohlen.", "Recommended for remaining principal calculation."))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L10n.t("Anfangsschuld", "Initial principal"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("optional, z. B. 18000,00", value: $editInstallmentInitialPrincipal, format: .number.precision(.fractionLength(2)))
                                    .keyboardType(.decimalPad)
                                    .focused($isAmountFieldFocused)
                            }
                            if editInstallmentLoanRepaymentMode == .annuity {
                                Text(L10n.t("Für Restschuld-Anzeige bitte Anfangsschuld und Sollzins eintragen.", "For remaining principal display, please enter initial principal and nominal interest."))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if isEditingLoan, let plan = editingInstallmentPlan {
                        Section(L10n.t("Sondertilgung", "Special repayment")) {
                            DatePicker(L10n.t("Datum", "Date"), selection: $editSpecialRepaymentDate, displayedComponents: .date)
                            TextField(L10n.t("Betrag in EUR", "Amount in EUR"), text: $editSpecialRepaymentAmountText)
                                .keyboardType(.decimalPad)
                                .focused($isAmountFieldFocused)

                            Button(L10n.t("Sondertilgung hinzufügen", "Add special repayment")) {
                                addSpecialRepayment(to: plan)
                            }
                            .buttonStyle(.borderedProminent)

                            let planRepayments = specialRepayments
                                .filter { $0.planID == plan.id }
                                .sorted { $0.repaymentDate > $1.repaymentDate }

                            if planRepayments.isEmpty {
                                Text(L10n.t("Noch keine Sondertilgungen erfasst.", "No special repayments added yet."))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(planRepayments) { repayment in
                                    HStack {
                                        Text(repayment.repaymentDate.formatted(date: .abbreviated, time: .omitted))
                                        Spacer()
                                        Text(repayment.amount.formatted(.currency(code: "EUR")))
                                            .fontWeight(.medium)
                                            .monospacedDigit()
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            modelContext.delete(repayment)
                                            do {
                                                try modelContext.save()
                                            } catch {
                                                NSLog("Mnemor: delete special repayment failed: \(error.localizedDescription)")
                                            }
                                            refreshExportFile()
                                        } label: {
                                            Text(L10n.t("Löschen", "Delete"))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .id(editingInstallmentPlan?.id)
                .onAppear {
                    if let plan = editingInstallmentPlan {
                        applyInstallmentEditState(from: plan)
                    }
                }
                .navigationTitle(isEditingLoan ? L10n.t("Kredit bearbeiten", "Edit loan") : L10n.t("Fixkosten bearbeiten", "Edit fixed cost"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.t("Abbrechen", "Cancel")) {
                            isShowingEditInstallmentSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.t("Speichern", "Save")) {
                            saveEditedInstallmentPlan()
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(L10n.t("Fertig", "Done")) {
                            isAmountFieldFocused = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            }
        }
        .sheet(item: $specialRepaymentPlanForSheet) { plan in
            NavigationStack {
                Form {
                    Section(L10n.t("Sondertilgung", "Special repayment")) {
                        DatePicker(L10n.t("Datum", "Date"), selection: $editSpecialRepaymentDate, displayedComponents: .date)
                        TextField(L10n.t("Betrag in EUR", "Amount in EUR"), text: $editSpecialRepaymentAmountText)
                            .keyboardType(.decimalPad)
                            .focused($isAmountFieldFocused)

                        Button(L10n.t("Sondertilgung hinzufügen", "Add special repayment")) {
                            addSpecialRepayment(to: plan)
                        }
                        .buttonStyle(.borderedProminent)

                        let planRepayments = specialRepayments
                            .filter { $0.planID == plan.id }
                            .sorted { $0.repaymentDate > $1.repaymentDate }

                        if planRepayments.isEmpty {
                            Text(L10n.t("Noch keine Sondertilgungen erfasst.", "No special repayments added yet."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(planRepayments) { repayment in
                                HStack {
                                    Text(repayment.repaymentDate.formatted(date: .abbreviated, time: .omitted))
                                    Spacer()
                                    Text(repayment.amount.formatted(.currency(code: "EUR")))
                                        .fontWeight(.medium)
                                        .monospacedDigit()
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        modelContext.delete(repayment)
                                        do {
                                            try modelContext.save()
                                        } catch {
                                            NSLog("Mnemor: delete special repayment failed: \(error.localizedDescription)")
                                        }
                                        refreshExportFile()
                                    } label: {
                                        Text(L10n.t("Löschen", "Delete"))
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle(L10n.t("Sondertilgung", "Special repayment"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.t("Abbrechen", "Cancel")) {
                            specialRepaymentPlanForSheet = nil
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(L10n.t("Fertig", "Done")) {
                            isAmountFieldFocused = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var reportsPlanningSections: some View {
        if mode == .reports {
            Section("\(L10n.t("Liquiditätsplanung", "Liquidity planning")) (\(planningWeeks) \(L10n.t("Wochen", "weeks")))") {
                Picker(L10n.t("Zeitraum", "Range"), selection: $planningWeeks) {
                    Text("6").tag(6)
                    Text("12").tag(12)
                    Text("24").tag(24)
                }
                .pickerStyle(.segmented)

                Toggle(L10n.t("Aktuellen Kontostand verwenden", "Use current account balance"), isOn: $useCurrentBalance)
                if useCurrentBalance {
                    TextField(L10n.t("Aktueller Kontostand", "Current balance"), value: $currentBalance, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .focused($isAmountFieldFocused)
                } else {
                    TextField(L10n.t("Startbestand", "Starting balance"), value: $startBalance, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .focused($isAmountFieldFocused)
                }

                if !effectiveUseCurrentBalance && overdueOpenAmount > 0 {
                    LabeledContent(L10n.t("Überfällig/sofort", "Overdue/immediate"), value: overdueOpenAmount.formatted(.currency(code: "EUR")))
                        .foregroundStyle(.red)
                }

                ForEach(weeklyPlanRows) { row in
                    let netDelta = row.income - row.totalOutgoing
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.label)
                                .font(.subheadline)
                            Spacer()
                            Text(row.projectedBalance.formatted(.currency(code: "EUR")))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .foregroundStyle(row.projectedBalance < 0 ? .red : .primary)
                        }
                        HStack {
                            Text("\(L10n.t("Rechnung", "Invoice")) \(row.invoiceOutgoing.formatted(.currency(code: "EUR"))) · \(L10n.t("Fixkosten/Kredite", "Fixed costs/Loans")) \(row.installmentOutgoing.formatted(.currency(code: "EUR"))) · \(L10n.t("Einnahmen", "Income")) \(row.income.formatted(.currency(code: "EUR")))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        HStack {
                            Text(L10n.t("Saldo Woche", "Weekly net"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(netDelta.formatted(.currency(code: "EUR").sign(strategy: .always())))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(netDelta < 0 ? .red : .green)
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedWeekStart = row.weekStart
                    }
                }
            }

            Section("Chart (\(planningWeeks) \(L10n.t("Wochen", "weeks")))") {
                Chart {
                    ForEach(weeklyCashflowBars) { bar in
                        BarMark(
                            x: .value("Woche", bar.weekStart, unit: .weekOfYear),
                            y: .value("Betrag", bar.amount),
                            width: .ratio(0.9)
                        )
                        .foregroundStyle(by: .value("Typ", bar.type))
                        .position(by: .value("Typ", bar.type), axis: .horizontal, span: .ratio(1))
                    }

                    ForEach(weeklyPlanRows) { row in
                        LineMark(
                            x: .value("Woche", row.weekStart),
                            y: .value("Betrag", row.projectedBalance)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Typ", L10n.t("Kontostand", "Balance")))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        PointMark(
                            x: .value("Woche", row.weekStart),
                            y: .value("Betrag", row.projectedBalance)
                        )
                        .foregroundStyle(by: .value("Typ", L10n.t("Kontostand", "Balance")))
                    }

                    RuleMark(y: .value("Null", 0))
                        .foregroundStyle(.gray.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartForegroundStyleScale([
                    L10n.t("Ausgaben", "Expenses"): .red.opacity(0.55),
                    L10n.t("Einnahmen", "Income"): .green.opacity(0.55),
                    L10n.t("Kontostand", "Balance"): AppTheme.accent
                ])
                .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount.formatted(.currency(code: "EUR")))
                            }
                        }
                    }
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
            }

            Section(L10n.t("Wochen-Details", "Weekly details")) {
                ForEach(weeklyDetailRows) { row in
                    DisclosureGroup {
                        if row.totalOutgoing <= 0 {
                            Text(L10n.t("Keine Ausgaben in dieser Woche.", "No expenses in this week."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.t("Fixkosten/Kredite", "Fixed costs/Loans"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(row.installmentOutgoing.formatted(.currency(code: "EUR")))
                                    .fontWeight(.medium)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.t("Nach Kategorie", "By category"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(row.categoryBreakdown) { item in
                                    HStack {
                                        Text(item.name)
                                        Spacer()
                                        Text(item.amount.formatted(.currency(code: "EUR")))
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(row.label)
                                .font(.subheadline.weight(.semibold))
                            if selectedWeekStart == row.weekStart {
                                Text(L10n.t("Ausgewählt", "Selected"))
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            Spacer()
                            Text(row.totalOutgoing.formatted(.currency(code: "EUR")))
                                .monospacedDigit()
                                .foregroundStyle(row.totalOutgoing > 0 ? .primary : .secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var reportsInvoiceSections: some View {
        if mode == .reports && selectedReportsTab == .invoices {
            Section(L10n.t("Nach Kategorie", "By category")) {
                if categoryRows.isEmpty {
                    ContentUnavailableView(L10n.t("Keine Daten", "No data"), systemImage: "chart.pie")
                } else {
                    ForEach(categoryRows) { row in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.name)
                                    .font(.headline.weight(.semibold))
                                Text(L10n.isEnglish ? "\(row.count) invoice(s)" : "\(row.count) Rechnung(en)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(row.amount.formatted(.currency(code: "EUR")))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                }
            }

            Section(L10n.t("Nach Anbieter", "By vendor")) {
                if vendorRows.isEmpty {
                    ContentUnavailableView(L10n.t("Keine Daten", "No data"), systemImage: "building.2")
                } else {
                    ForEach(vendorRows) { row in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.vendor)
                                    .font(.headline.weight(.semibold))
                                Text(L10n.isEnglish ? "\(row.count) invoice(s)" : "\(row.count) Rechnung(en)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(row.total.formatted(.currency(code: "EUR")))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }

    private func metricsCard(rows: [(title: String, value: String, highlight: Bool)]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .firstTextBaseline) {
                    Text(row.title)
                        .font(row.highlight ? .body.weight(.medium) : .subheadline)
                        .foregroundStyle(Color(red: 0.20, green: 0.28, blue: 0.38))
                    Spacer(minLength: 10)
                    Text(row.value)
                        .font(row.highlight ? .title3.weight(.semibold) : .body.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(Color(red: 0.10, green: 0.16, blue: 0.24))
                }
                .padding(.vertical, row.highlight ? 14 : 10)
                if index < rows.count - 1 {
                    Rectangle()
                        .fill(Color(red: 0.78, green: 0.84, blue: 0.90))
                        .frame(height: 1.5)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.80, green: 0.86, blue: 0.92), lineWidth: 1.2)
        )
    }

    @ViewBuilder
    private var fixedCostSections: some View {
        if mode == .expenses && selectedTab == .fixedCosts {
            Section(L10n.t("Fixkosten/Kredit erfassen", "Create fixed cost/loan")) {
                Picker(L10n.t("Typ", "Type"), selection: $installmentKind) {
                    ForEach(InstallmentPlan.Kind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t("Bezeichnung", "Name"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("z. B. Auto Leasing", text: $installmentName)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(
                        installmentKind == .loan && installmentLoanRepaymentMode == .fixedPrincipal
                            ? L10n.t("Monatliche Tilgung", "Monthly principal")
                            : L10n.t("Monatliche Rate", "Monthly payment")
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("z. B. 420,00", value: $installmentMonthlyPayment, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .focused($isAmountFieldFocused)
                }

                if installmentKind == .loan {
                    Picker(L10n.t("Kreditart", "Loan type"), selection: $installmentLoanRepaymentMode) {
                        ForEach(InstallmentPlan.LoanRepaymentMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if installmentLoanRepaymentMode == .fixedPrincipal {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.t("Sollzins p.a. (%)", "Nominal interest p.a. (%)"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("z. B. 5,49", value: $installmentAnnualInterestRate, format: .number.precision(.fractionLength(3)))
                                .keyboardType(.decimalPad)
                                .focused($isAmountFieldFocused)
                            Text(L10n.t("Pflichtfeld bei fester Tilgung.", "Required for fixed principal mode."))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.t("Sollzins p.a. (%)", "Nominal interest p.a. (%)"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("optional, z. B. 5,49", value: $installmentAnnualInterestRate, format: .number.precision(.fractionLength(3)))
                                .keyboardType(.decimalPad)
                                .focused($isAmountFieldFocused)
                            Text(L10n.t("Für Restschuld-Berechnung empfohlen.", "Recommended for remaining principal calculation."))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.t("Anfangsschuld", "Initial principal"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("optional, z. B. 18000,00", value: $installmentInitialPrincipal, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .focused($isAmountFieldFocused)
                    }
                    if installmentLoanRepaymentMode == .annuity {
                        Text(L10n.t("Für Restschuld-Anzeige bitte Anfangsschuld und Sollzins eintragen.", "For remaining principal display, please enter initial principal and nominal interest."))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DatePicker(L10n.t("Startdatum", "Start date"), selection: $installmentStartDate, displayedComponents: .date)
                Stepper("\(L10n.t("Fälligkeitstag", "Due day")): \(installmentPaymentDay).", value: $installmentPaymentDay, in: 1...28)
                Toggle(L10n.t("Enddatum setzen", "Set end date"), isOn: $installmentHasEndDate)
                if installmentHasEndDate {
                    DatePicker(L10n.t("Enddatum", "End date"), selection: $installmentEndDate, displayedComponents: .date)
                }
                if installmentKind == .loan {
                    Button(L10n.t("Kredit speichern", "Save loan")) {
                        addInstallmentPlan(forceKind: .loan)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(L10n.t("Fixkosten speichern", "Save fixed cost")) {
                        addInstallmentPlan(forceKind: .fixedCost)
                    }
                    .buttonStyle(.borderedProminent)
                }
                if let installmentValidationMessage {
                    Text(installmentValidationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section(L10n.t("Übersicht", "Overview")) {
                if sortedInstallmentPlans.isEmpty {
                    Text(L10n.t("Keine Fixkosten/Kredite hinterlegt.", "No fixed costs/loans added."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedInstallmentPlans) { plan in
                        let rowKind = resolvedInstallmentKind(for: plan)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(plan.name)
                                    Text(rowKind.title)
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            rowKind == .loan
                                                ? Color(red: 0.95, green: 0.80, blue: 0.62)
                                                : Color(red: 0.84, green: 0.87, blue: 0.92)
                                        )
                                        .foregroundStyle(
                                            rowKind == .loan
                                                ? Color(red: 0.36, green: 0.20, blue: 0.09)
                                                : Color(red: 0.18, green: 0.24, blue: 0.35)
                                        )
                                        .clipShape(Capsule())
                                }
                                Text(rateSubtitle(plan))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(currentInstallmentTotal(for: plan).formatted(.currency(code: "EUR")))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                if rowKind == .loan {
                                    Text("\(L10n.t("Zins", "Interest")) \(currentInstallmentSplit(for: plan).interest.formatted(.currency(code: "EUR"))) · \(L10n.t("Tilgung", "Principal")) \(currentInstallmentSplit(for: plan).principal.formatted(.currency(code: "EUR")))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    if let remainingNow = remainingPrincipalAfterSpecialRepayments(of: plan, at: Date()) {
                                        Text("\(L10n.t("Restschuld heute", "Remaining principal today")) \(remainingNow.formatted(.currency(code: "EUR")))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .swipeActions {
                            if rowKind == .loan {
                                Button {
                                    beginSpecialRepayment(for: plan)
                                } label: {
                                    Text(L10n.t("Sondertilgung", "Special repayment"))
                                }
                                .tint(Color(red: 0.14, green: 0.28, blue: 0.48))
                            }
                            Button {
                                beginEditingInstallmentPlan(plan, forcedKind: rowKind)
                            } label: {
                                Text(L10n.t("Bearbeiten", "Edit"))
                            }
                            .tint(AppTheme.accent)
                            Button(role: .destructive) {
                                modelContext.delete(plan)
                                do {
                                    try modelContext.save()
                                } catch {
                                    NSLog("Mnemor: delete installment plan failed: \(error.localizedDescription)")
                                }
                                refreshExportFile()
                            } label: {
                                Text(L10n.t("Löschen", "Delete"))
                            }
                        }
                    }
                }
            }
        }
    }

    private var availableMonths: [Date] {
        let sourceInvoices = mode == .reports ? invoices : scopedInvoices
        let months = Set(sourceInvoices.map { startOfMonth(for: $0.receivedAt) })
        if months.isEmpty {
            return [startOfMonth(for: Date())]
        }
        return months.sorted(by: >)
    }

    private var scopedInvoices: [Invoice] {
        switch dataScope {
        case .open:
            return invoices.filter { $0.status == .open }
        case .all:
            return invoices
        }
    }

    private var monthlyInvoices: [Invoice] {
        scopedInvoices.filter { invoice in
            calendar.isDate(invoice.receivedAt, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var monthlyInvoicesAll: [Invoice] {
        invoices.filter { invoice in
            calendar.isDate(invoice.receivedAt, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var totalAmount: Decimal {
        monthlyInvoices.reduce(Decimal.zero) { partial, invoice in
            partial + (invoice.amount ?? 0)
        }
    }

    private var openCount: Int {
        monthlyInvoices.filter { $0.status == .open }.count
    }

    private var paidCount: Int {
        monthlyInvoices.filter { $0.status == .paid }.count
    }

    private var monthlyInvoiceCountAll: Int {
        monthlyInvoicesAll.count
    }

    private var monthlyInvoiceAmountAll: Decimal {
        monthlyInvoicesAll.reduce(Decimal.zero) { $0 + ($1.amount ?? 0) }
    }

    private var monthlyOpenInvoicesAll: [Invoice] {
        monthlyInvoicesAll.filter { $0.status == .open }
    }

    private var monthlyOpenInvoiceCount: Int {
        monthlyOpenInvoicesAll.count
    }

    private var monthlyOpenInvoiceAmount: Decimal {
        monthlyOpenInvoicesAll.reduce(Decimal.zero) { $0 + ($1.amount ?? 0) }
    }

    private var monthlyPaidInvoicesAll: [Invoice] {
        monthlyInvoicesAll.filter { $0.status == .paid }
    }

    private var monthlyPaidInvoiceCount: Int {
        monthlyPaidInvoicesAll.count
    }

    private var monthlyPaidInvoiceAmount: Decimal {
        monthlyPaidInvoicesAll.reduce(Decimal.zero) { $0 + ($1.amount ?? 0) }
    }

    private var monthlyInstallmentOccurrences: [MonthlyInstallmentOccurrence] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else { return [] }
        let today = calendar.startOfDay(for: Date())

        return sortedInstallmentPlans
            .filter(\.isActive)
            .compactMap { plan in
                let planStart = calendar.startOfDay(for: plan.startDate)
                let dayRange = calendar.range(of: .day, in: .month, for: monthInterval.start) ?? 1..<29
                let paymentDay = min(max(plan.paymentDay, 1), dayRange.count)
                guard let dueDate = calendar.date(byAdding: .day, value: paymentDay - 1, to: monthInterval.start) else {
                    return nil
                }
                let dueDay = calendar.startOfDay(for: dueDate)
                guard dueDay >= monthInterval.start && dueDay < monthInterval.end else { return nil }
                guard dueDay >= planStart else { return nil }
                if let planEnd = plan.endDate.map({ calendar.startOfDay(for: $0) }), dueDay > planEnd { return nil }

                return MonthlyInstallmentOccurrence(
                    planName: plan.name,
                    dueDate: dueDay,
                    amount: installmentTotalAmount(for: plan, dueDate: dueDay),
                    isOpen: dueDay >= today
                )
            }
    }

    private var monthlyOpenFixedCostCount: Int {
        monthlyInstallmentOccurrences.filter(\.isOpen).count
    }

    private var monthlyPaidFixedCostCount: Int {
        monthlyInstallmentOccurrences.filter { !$0.isOpen }.count
    }

    private var monthlyOpenFixedCostAmount: Decimal {
        monthlyInstallmentOccurrences
            .filter(\.isOpen)
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var monthlyPaidFixedCostAmount: Decimal {
        monthlyInstallmentOccurrences
            .filter { !$0.isOpen }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var monthlyTotalOpenAmount: Decimal {
        monthlyOpenInvoiceAmount + monthlyOpenFixedCostAmount
    }

    private var monthlyTotalPaidAmount: Decimal {
        monthlyPaidInvoiceAmount + monthlyPaidFixedCostAmount
    }

    private var monthlyTotalAmount: Decimal {
        monthlyTotalOpenAmount + monthlyTotalPaidAmount
    }

    private var reportMonthStart: Date {
        startOfMonth(for: selectedMonth)
    }

    private var reportAsOfLabel: String {
        let today = calendar.startOfDay(for: Date())
        return "Stand \(today.formatted(.dateTime.day().month().year()))"
    }

    private var reportAsOfDateText: String {
        let today = calendar.startOfDay(for: Date())
        return today.formatted(.dateTime.day().month().year())
    }

    private var reportMonthEndExclusive: Date {
        calendar.date(byAdding: .month, value: 1, to: reportMonthStart) ?? reportMonthStart
    }

    private var reportAsOfEndExclusive: Date {
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
        let clampedUpper = min(tomorrow, reportMonthEndExclusive)
        return max(reportMonthStart, clampedUpper)
    }

    private var reportActualIncome: Double {
        incomeForPeriod(start: reportMonthStart, endExclusive: reportAsOfEndExclusive)
    }

    private var reportPendingIncome: Double {
        incomeForPeriod(start: reportAsOfEndExclusive, endExclusive: reportMonthEndExclusive)
    }

    private var reportActualInvoiceExpenses: Double {
        invoicesForReportPeriod(start: reportMonthStart, endExclusive: reportAsOfEndExclusive)
            .reduce(0) { $0 + amountValue(for: $1) }
    }

    private var reportPendingInvoiceExpenses: Double {
        invoicesForReportPeriod(start: reportAsOfEndExclusive, endExclusive: reportMonthEndExclusive)
            .reduce(0) { $0 + amountValue(for: $1) }
    }

    private var reportActualFixedExpenses: Double {
        monthlyInstallmentOccurrences
            .filter { $0.dueDate >= reportMonthStart && $0.dueDate < reportAsOfEndExclusive }
            .reduce(0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
    }

    private var reportPendingFixedExpenses: Double {
        monthlyInstallmentOccurrences
            .filter { $0.dueDate >= reportAsOfEndExclusive && $0.dueDate < reportMonthEndExclusive }
            .reduce(0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
    }

    private var reportActualExpenses: Double {
        reportActualInvoiceExpenses + reportActualFixedExpenses
    }

    private var reportPendingExpenses: Double {
        reportPendingInvoiceExpenses + reportPendingFixedExpenses
    }

    private var reportPendingDifference: Double {
        reportPendingIncome - reportPendingExpenses
    }

    private var reportActualDifference: Double {
        reportActualIncome - reportActualExpenses
    }

    private var reportPlannedMonthEndDifference: Double {
        (reportActualIncome + reportPendingIncome) - (reportActualExpenses + reportPendingExpenses)
    }

    private var vendorRows: [VendorRow] {
        var grouped: [String: VendorRow] = [:]
        for invoice in reportInvoicesForSelectedMonth {
            let vendorDisplay = cleanedDisplayName(from: invoice.vendorName, fallback: "Unbekannt")
            let normalizedVendor = normalizedPartyKey(vendorDisplay)
            let current = grouped[normalizedVendor] ?? VendorRow(vendor: vendorDisplay, total: 0, count: 0)
            grouped[normalizedVendor] = VendorRow(
                vendor: current.vendor,
                total: current.total + (invoice.amount ?? 0),
                count: current.count + 1
            )
        }
        return Array(grouped.values).sorted { $0.total > $1.total }
    }

    private func cleanedDisplayName(from raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }

    private func normalizedPartyKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }

    private func invoicesForReportPeriod(start: Date, endExclusive: Date) -> [Invoice] {
        guard start < endExclusive else { return [] }
        return invoices.filter { invoice in
            let date = targetDate(for: invoice)
            return date >= start && date < endExclusive
        }
    }

    private func incomeForPeriod(start: Date, endExclusive: Date) -> Double {
        guard start < endExclusive else { return 0 }
        return sortedIncomeEntries
            .filter(\.isActive)
            .reduce(0) { partial, entry in
                partial + incomeAmount(for: entry, start: start, endExclusive: endExclusive)
            }
    }

    private var categoryRows: [CategoryRow] {
        var grouped: [String: CategoryRow] = [:]
        for invoice in reportInvoicesForSelectedMonth {
            let key = invoice.category
            let current = grouped[key] ?? CategoryRow(name: key, amount: 0, count: 0)
            grouped[key] = CategoryRow(
                name: key,
                amount: current.amount + (invoice.amount ?? 0),
                count: current.count + 1
            )
        }
        return Array(grouped.values).sorted { $0.amount > $1.amount }
    }

    private var reportInvoicesForSelectedMonth: [Invoice] {
        let inMonth = monthlyInvoicesAll
        switch reportInvoiceStatusScope {
        case .open:
            return inMonth.filter { $0.status == .open }
        case .paid:
            return inMonth.filter { $0.status == .paid }
        case .all:
            return inMonth
        }
    }

    private func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private func monthLabel(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    private var overdueOpenAmount: Double {
        let today = calendar.startOfDay(for: Date())
        return openInvoices.reduce(0) { partial, invoice in
            let target = targetDate(for: invoice)
            guard target < today else { return partial }
            return partial + amountValue(for: invoice)
        }
    }

    private var weeklyPlanRows: [WeeklyLiquidityRow] {
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let projectionStart = effectiveUseCurrentBalance ? today : weekStart

        var rows: [WeeklyLiquidityRow] = []
        let initialOverdueDeduction = effectiveUseCurrentBalance ? 0 : overdueOpenAmount
        var runningBalance = planningBaseBalance - initialOverdueDeduction

        for offset in 0..<planningWeeks {
            guard let start = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStart),
                  let end = calendar.date(byAdding: .day, value: 7, to: start) else { continue }
            let intervalStart = max(start, projectionStart)
            guard intervalStart < end else { continue }

            let weekInvoices = openInvoices.filter { invoice in
                let due = targetDate(for: invoice)
                return due >= intervalStart && due < end
            }
            let weekInvoiceOutgoing = weekInvoices.reduce(0) { $0 + amountValue(for: $1) }
            let weekInstallmentOutgoing = installmentOutgoingForWeek(start: intervalStart, endExclusive: end)
            let weekOutgoing = weekInvoiceOutgoing + weekInstallmentOutgoing
            let weekIncome = incomeForWeek(start: intervalStart, endExclusive: end)
            let categoryBreakdown = buildCategoryBreakdown(weekInvoices)

            runningBalance += weekIncome - weekOutgoing
            rows.append(
                WeeklyLiquidityRow(
                    weekStart: start,
                    label: weekLabel(start: start, end: end),
                    income: weekIncome,
                    invoiceOutgoing: weekInvoiceOutgoing,
                    installmentOutgoing: weekInstallmentOutgoing,
                    totalOutgoing: weekOutgoing,
                    projectedBalance: runningBalance,
                    categoryBreakdown: categoryBreakdown
                )
            )
        }
        return rows
    }

    private var weeklyDetailRows: [WeeklyLiquidityRow] {
        guard let selectedWeekStart else { return weeklyPlanRows }
        return weeklyPlanRows.sorted { lhs, rhs in
            if lhs.weekStart == selectedWeekStart { return true }
            if rhs.weekStart == selectedWeekStart { return false }
            return lhs.weekStart < rhs.weekStart
        }
    }

    private var weeklyPlanRowsSignature: String {
        let balances = weeklyPlanRows.map { numberString($0.projectedBalance) }.joined(separator: "|")
        return "\(negativeCashflowAlertEnabled)|\(negativeCashflowAlertWeeks)|\(balances)"
    }

    private var weeklyCashflowBars: [WeeklyCashflowBar] {
        weeklyPlanRows.flatMap { row in
            [
                WeeklyCashflowBar(weekStart: row.weekStart, type: L10n.t("Ausgaben", "Expenses"), amount: row.totalOutgoing),
                WeeklyCashflowBar(weekStart: row.weekStart, type: L10n.t("Einnahmen", "Income"), amount: row.income)
            ]
        }
    }

    private func updateNegativeCashflowAlertIfNeeded() async {
        guard negativeCashflowAlertEnabled else {
            notificationService.cancelNegativeCashflowAlert()
            return
        }

        let granted = await notificationService.requestAuthorization()
        guard granted else { return }

        let limitedRows = Array(weeklyPlanRows.prefix(max(1, negativeCashflowAlertWeeks)))
        if let firstNegative = limitedRows.first(where: { $0.projectedBalance < 0 }) {
            await notificationService.scheduleNegativeCashflowAlert(
                weekLabel: firstNegative.label,
                projectedBalance: firstNegative.projectedBalance
            )
        } else {
            notificationService.cancelNegativeCashflowAlert()
        }
    }

    private var openInvoices: [Invoice] {
        invoices.filter { $0.status == .open }
    }

    private var sortedInstallmentPlans: [InstallmentPlan] {
        installmentPlans.sorted { lhs, rhs in
            if lhs.isActive != rhs.isActive { return lhs.isActive && !rhs.isActive }
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private var sortedLoanPlans: [InstallmentPlan] {
        sortedInstallmentPlans.filter { $0.kind == .loan }
    }

    private func targetDate(for invoice: Invoice) -> Date {
        invoice.dueDate ?? invoice.receivedAt
    }

    private func amountValue(for invoice: Invoice) -> Double {
        guard let amount = invoice.amount else { return 0 }
        return NSDecimalNumber(decimal: amount).doubleValue
    }

    private func weekLabel(start: Date, end: Date) -> String {
        let weekEnd = calendar.date(byAdding: .day, value: -1, to: end) ?? end
        return "\(start.formatted(.dateTime.day().month())) - \(weekEnd.formatted(.dateTime.day().month()))"
    }

    private func buildCategoryBreakdown(_ invoices: [Invoice]) -> [BreakdownItem] {
        var grouped: [String: Double] = [:]
        for invoice in invoices {
            grouped[invoice.category, default: 0] += amountValue(for: invoice)
        }
        return grouped
            .map { BreakdownItem(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    private func installmentOutgoingForWeek(start: Date, endExclusive: Date) -> Double {
        sortedInstallmentPlans.filter(\.isActive).reduce(0) { partial, plan in
            partial + installmentAmount(for: plan, start: start, endExclusive: endExclusive)
        }
    }

    private func installmentAmount(for plan: InstallmentPlan, start: Date, endExclusive: Date) -> Double {
        guard start < endExclusive else { return 0 }
        let planStart = calendar.startOfDay(for: plan.startDate)
        let planEnd = plan.endDate.map { calendar.startOfDay(for: $0) }

        let monthAnchors = uniqueMonthsBetween(start: start, endExclusive: endExclusive)
        var total = 0.0

        for monthAnchor in monthAnchors {
            guard let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor) else { continue }
            let dayRange = calendar.range(of: .day, in: .month, for: monthAnchor) ?? 1..<29
            let paymentDay = min(max(plan.paymentDay, 1), dayRange.count)
            guard let paymentDate = calendar.date(byAdding: .day, value: paymentDay - 1, to: monthInterval.start) else { continue }
            guard paymentDate >= start && paymentDate < endExclusive else { continue }
            guard paymentDate >= planStart else { continue }
            if let planEnd, paymentDate > planEnd { continue }
            total += NSDecimalNumber(decimal: installmentTotalAmount(for: plan, dueDate: paymentDate)).doubleValue
        }
        return total
    }

    private func incomeForWeek(start: Date, endExclusive: Date) -> Double {
        sortedIncomeEntries.filter(\.isActive).reduce(0) { partial, entry in
            partial + incomeAmount(for: entry, start: start, endExclusive: endExclusive)
        }
    }

    private func incomeAmount(for entry: IncomeEntry, start: Date, endExclusive: Date) -> Double {
        switch entry.kind {
        case .oneTime:
            let day = calendar.startOfDay(for: entry.startDate)
            return (day >= start && day < endExclusive) ? NSDecimalNumber(decimal: entry.amount).doubleValue : 0
        case .monthlyFixed:
            return monthlyIncomeAmount(for: entry, start: start, endExclusive: endExclusive)
        }
    }

    private func monthlyIncomeAmount(for entry: IncomeEntry, start: Date, endExclusive: Date) -> Double {
        let dayOfMonth = calendar.component(.day, from: entry.startDate)
        let monthAnchors = uniqueMonthsBetween(start: start, endExclusive: endExclusive)
        var total = 0.0

        for monthAnchor in monthAnchors {
            guard let interval = calendar.dateInterval(of: .month, for: monthAnchor) else { continue }
            let dayRange = calendar.range(of: .day, in: .month, for: monthAnchor) ?? 1..<29
            let targetDay = min(dayOfMonth, dayRange.count)
            guard let payoutDate = calendar.date(byAdding: .day, value: targetDay - 1, to: interval.start) else { continue }
            guard payoutDate >= start && payoutDate < endExclusive && payoutDate >= calendar.startOfDay(for: entry.startDate) else { continue }
            total += NSDecimalNumber(decimal: entry.amount).doubleValue
        }
        return total
    }

    private func uniqueMonthsBetween(start: Date, endExclusive: Date) -> [Date] {
        guard start < endExclusive else { return [] }
        let first = startOfMonth(for: start)
        let last = startOfMonth(for: calendar.date(byAdding: .day, value: -1, to: endExclusive) ?? start)
        var months: [Date] = []
        var current = first
        while current <= last {
            months.append(current)
            current = calendar.date(byAdding: .month, value: 1, to: current) ?? current.addingTimeInterval(31 * 24 * 3600)
        }
        return months
    }

    @discardableResult
    private func refreshExportFile() -> Bool {
        let format = ["xlsx", "csv", "xml"].contains(exportFormat) ? exportFormat : "xlsx"
        let fileName = "billremind-auswertung-\(selectedMonth.formatted(.dateTime.year().month(.twoDigits))).\(format)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        exportURL = nil
        do {
            switch format {
            case "xlsx":
                guard let data = buildWorkbookXLSXData() else {
                    return false
                }
                try data.write(to: url)
            case "csv":
                try buildWorkbookCSV().write(to: url, atomically: true, encoding: .utf8)
            case "xml":
                try buildWorkbookXML().write(to: url, atomically: true, encoding: .utf8)
            default:
                guard let data = buildWorkbookXLSXData() else {
                    return false
                }
                try data.write(to: url)
            }
            exportURL = url
            return true
        } catch {
            return false
        }
    }

    private func makeWorksheets() -> [(String, [[String]])] {
        let monthMetaRows: [[String]] = {
            let baseRows = [
                [L10n.t("Monat", "Month"), monthLabel(for: selectedMonth)],
                [L10n.t("Datenbasis", "Data scope"), dataScope.title],
                [L10n.t("Liquiditäts-Basis", "Liquidity basis"), effectiveUseCurrentBalance ? L10n.t("Aktueller Kontostand", "Current balance") : L10n.t("Startbestand", "Starting balance")],
                [L10n.t("Basiswert", "Base value"), numberString(planningBaseBalance)]
            ]

            if mode == .reports {
                return baseRows + [
                    [L10n.t("Einnahmen", "Income") + " (\(reportAsOfLabel))", numberString(reportActualIncome)],
                    [L10n.t("Ausgaben", "Expenses") + " (\(reportAsOfLabel))", numberString(reportActualExpenses)],
                    [L10n.t("Differenz", "Difference") + " (\(reportAsOfLabel))", numberString(reportActualDifference)],
                    [L10n.t("Noch fällig Einnahmen", "Pending income"), numberString(reportPendingIncome)],
                    [L10n.t("Noch fällig Ausgaben", "Pending expenses"), numberString(reportPendingExpenses)],
                    [L10n.t("Noch fällige Differenz", "Pending difference"), numberString(reportPendingDifference)],
                    [L10n.t("Differenz Monatsende", "Month-end difference"), numberString(reportPlannedMonthEndDifference)]
                ]
            }

            if dataScope == .open {
                return baseRows + [
                    ["Anzahl Rechnungen", "\(monthlyOpenInvoiceCount)"],
                    ["Betrag Rechnungen", decimalString(monthlyOpenInvoiceAmount)],
                    ["Fixkosten offen (Anzahl)", "\(monthlyOpenFixedCostCount)"],
                    ["Fixkosten offen (Betrag)", decimalString(monthlyOpenFixedCostAmount)],
                    ["Gesamt offen", decimalString(monthlyTotalOpenAmount)]
                ]
            }

            return baseRows + [
                ["Anzahl Rechnungen", "\(monthlyInvoiceCountAll)"],
                ["Betrag Rechnungen", decimalString(monthlyInvoiceAmountAll)],
                ["Rechnungen offen (Anzahl)", "\(monthlyOpenInvoiceCount)"],
                ["Rechnungen offen (Betrag)", decimalString(monthlyOpenInvoiceAmount)],
                ["Rechnungen bezahlt (Anzahl)", "\(monthlyPaidInvoiceCount)"],
                ["Rechnungen bezahlt (Betrag)", decimalString(monthlyPaidInvoiceAmount)],
                ["Fixkosten offen (Anzahl)", "\(monthlyOpenFixedCostCount)"],
                ["Fixkosten offen (Betrag)", decimalString(monthlyOpenFixedCostAmount)],
                ["Fixkosten bezahlt (Anzahl)", "\(monthlyPaidFixedCostCount)"],
                ["Fixkosten bezahlt (Betrag)", decimalString(monthlyPaidFixedCostAmount)]
            ]
        }()

        let invoiceDetailRows = monthlyInvoices
            .sorted { ($0.dueDate ?? $0.receivedAt) < ($1.dueDate ?? $1.receivedAt) }
            .map { invoice in
                [
                    dateString(invoice.receivedAt),
                    dateString(invoice.dueDate ?? invoice.receivedAt),
                    invoice.status == .open ? "Offen" : "Bezahlt",
                    invoice.vendorName,
                    invoice.category,
                    decimalString(invoice.amount ?? 0),
                    invoice.invoiceNumber ?? ""
                ]
            }
        let invoiceDetailTotal = [
            "SUMME", "", "", "", "",
            decimalString(invoiceDetailRows.reduce(Decimal.zero) { partial, row in
                partial + (Decimal(string: row[5]) ?? 0)
            }),
            ""
        ]

        let categoriesByAmount = categoryRows
            .sorted { $0.amount > $1.amount }
            .map { [$0.name, "\($0.count)", decimalString($0.amount)] }
        let categoriesByName = categoryRows
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { [$0.name, "\($0.count)", decimalString($0.amount)] }

        let categorySumRow = [
            "SUMME",
            "\(categoryRows.reduce(0) { $0 + $1.count })",
            decimalString(categoryRows.reduce(Decimal.zero) { $0 + $1.amount })
        ]

        let liquidityRows = weeklyPlanRows.map { row in
            [
                row.label,
                numberString(row.invoiceOutgoing),
                numberString(row.installmentOutgoing),
                numberString(row.totalOutgoing),
                numberString(row.income),
                numberString(row.projectedBalance)
            ]
        }
        let chartRows = weeklyPlanRows.map { row in
            [
                dateString(row.weekStart),
                row.label,
                numberString(row.income),
                numberString(row.totalOutgoing),
                numberString(row.projectedBalance)
            ]
        }
        let liquiditySumRow = [
            "SUMME",
            numberString(weeklyPlanRows.reduce(0) { $0 + $1.invoiceOutgoing }),
            numberString(weeklyPlanRows.reduce(0) { $0 + $1.installmentOutgoing }),
            numberString(weeklyPlanRows.reduce(0) { $0 + $1.totalOutgoing }),
            numberString(weeklyPlanRows.reduce(0) { $0 + $1.income }),
            numberString(weeklyPlanRows.last?.projectedBalance ?? planningBaseBalance)
        ]

        let installmentRows: [[String]] = sortedInstallmentPlans.map { plan -> [String] in
            let split = currentInstallmentSplit(for: plan)
            return [
                plan.name,
                plan.kind.title,
                plan.kind == .loan ? plan.loanRepaymentMode.title : "",
                dateString(plan.startDate),
                plan.endDate.map(dateString) ?? "",
                "\(plan.paymentDay).",
                plan.isActive ? "Ja" : "Nein",
                decimalString(plan.monthlyPayment),
                decimalString(plan.annualInterestRatePercent ?? 0),
                decimalString(split.interest),
                decimalString(split.principal)
            ]
        }
        let debtRows = sortedLoanPlans.map { plan in
            [
                plan.name,
                decimalString(plan.initialPrincipal ?? 0),
                decimalString(remainingPrincipalAfterSpecialRepayments(of: plan, at: Date()) ?? 0),
                decimalString(remainingPrincipalAfterSpecialRepayments(of: plan, at: calendar.date(byAdding: .month, value: 12, to: Date()) ?? Date()) ?? 0),
                decimalString(plan.monthlyPrincipal)
            ]
        }
        let installmentSumRow: [String] = [
            "SUMME (Aktiv)",
            "", "", "", "", "", "",
            decimalString(sortedInstallmentPlans.filter(\.isActive).reduce(Decimal.zero) { $0 + currentInstallmentTotal(for: $1) }),
            "",
            decimalString(sortedInstallmentPlans.filter(\.isActive).reduce(Decimal.zero) { total, plan in
                total + currentInstallmentSplit(for: plan).interest
            }),
            decimalString(sortedInstallmentPlans.filter(\.isActive).reduce(Decimal.zero) { total, plan in
                total + currentInstallmentSplit(for: plan).principal
            })
        ]

        let incomesRows = sortedIncomeEntries.map { entry in
            [
                entry.name,
                entry.kind.title,
                dateString(entry.startDate),
                entry.isActive ? "Ja" : "Nein",
                decimalString(entry.amount)
            ]
        }
        let specialRepaymentRows = specialRepayments
            .sorted { $0.repaymentDate < $1.repaymentDate }
            .map { item -> [String] in
                let planName = sortedInstallmentPlans.first(where: { $0.id == item.planID })?.name ?? "Unbekannt"
                return [planName, dateString(item.repaymentDate), decimalString(item.amount)]
            }
        let specialRepaymentSumRow = [
            "SUMME",
            "",
            decimalString(specialRepayments.reduce(Decimal.zero) { $0 + $1.amount })
        ]
        let incomesSumAll = [
            "SUMME (Alle)",
            "",
            "",
            "",
            decimalString(sortedIncomeEntries.reduce(Decimal.zero) { $0 + $1.amount })
        ]
        let incomesSumActive = [
            "SUMME (Aktiv)",
            "",
            "",
            "",
            decimalString(sortedIncomeEntries.filter(\.isActive).reduce(Decimal.zero) { $0 + $1.amount })
        ]

        let installmentsSheetRows: [[String]] =
            [[L10n.t("Bezeichnung", "Name"), L10n.t("Typ", "Type"), L10n.t("Modus", "Mode"), "Start", L10n.t("Ende", "End"), L10n.t("Tag", "Day"), L10n.t("Aktiv", "Active"), L10n.t("Rate_oder_Tilgung", "Rate_or_Repayment"), L10n.t("Sollzins_pa", "Interest_Rate_pa"), L10n.t("Zins_aktuell", "Current_Interest"), L10n.t("Tilgung_aktuell", "Current_Repayment")]]
            + installmentRows
            + [installmentSumRow]

        let worksheets: [(String, [[String]])] = [
            (L10n.t("Monatsübersicht", "Monthly_Overview"), [[L10n.t("Feld", "Field"), L10n.t("Wert", "Value")]] + monthMetaRows),
            (L10n.t("Rechnungsdetails", "Invoice_Details"), [[L10n.t("Eingang", "Received"), L10n.t("Fällig", "Due"), "Status", L10n.t("Anbieter", "Vendor"), L10n.t("Kategorie", "Category"), L10n.t("Betrag", "Amount"), L10n.t("Rechnungsnr", "Invoice_No")]] + invoiceDetailRows + [invoiceDetailTotal]),
            (L10n.t("Kategorien_nach_Betrag", "Categories_by_Amount"), [[L10n.t("Kategorie", "Category"), L10n.t("Anzahl", "Count"), L10n.t("Betrag", "Amount")]] + categoriesByAmount + [categorySumRow]),
            (L10n.t("Kategorien_nach_Name", "Categories_by_Name"), [[L10n.t("Kategorie", "Category"), L10n.t("Anzahl", "Count"), L10n.t("Betrag", "Amount")]] + categoriesByName + [categorySumRow]),
            (L10n.t("Liquidität", "Liquidity"), [[L10n.t("Woche", "Week"), L10n.t("Rechnung", "Invoice"), L10n.t("Fixkosten_Kredite", "Fixed_Costs_Loans"), L10n.t("Ausgaben_total", "Expenses_Total"), L10n.t("Einnahmen", "Income"), L10n.t("Prognose", "Forecast")]] + liquidityRows + [liquiditySumRow]),
            (L10n.t("Chart_Daten", "Chart_Data"), [[L10n.t("Woche_Start", "Week_Start"), L10n.t("Woche_Label", "Week_Label"), L10n.t("Einnahmen", "Income"), L10n.t("Ausgaben", "Expenses"), L10n.t("Kontostand", "Balance")]] + chartRows),
            (L10n.t("Fixkosten_Kredite", "Fixed_Costs_Loans"), installmentsSheetRows),
            (L10n.t("Sondertilgungen", "Special_Repayments"), [[L10n.t("Kredit", "Loan"), L10n.t("Datum", "Date"), L10n.t("Betrag", "Amount")]] + specialRepaymentRows + [specialRepaymentSumRow]),
            (L10n.t("Restschuld", "Remaining_Debt"), [[L10n.t("Bezeichnung", "Name"), L10n.t("Anfangsschuld", "Initial_Debt"), L10n.t("Restschuld_heute", "Remaining_Today"), L10n.t("Restschuld_12M", "Remaining_12M"), L10n.t("Tilgung_monat", "Monthly_Repayment")]] + debtRows),
            (L10n.t("Einnahmen", "Income"), [[L10n.t("Bezeichnung", "Name"), L10n.t("Typ", "Type"), "Start", L10n.t("Aktiv", "Active"), L10n.t("Betrag", "Amount")]] + incomesRows + [incomesSumAll, incomesSumActive])
        ]
        return worksheets
    }

    private func buildWorkbookXML() -> String {
        let worksheets = makeWorksheets()

        let workbookStart = """
        <?xml version="1.0"?>
        <?mso-application progid="Excel.Sheet"?>
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
         xmlns:o="urn:schemas-microsoft-com:office:office"
         xmlns:x="urn:schemas-microsoft-com:office:excel"
         xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
        """
        let workbookEnd = "</Workbook>"
        let sheetsXML = worksheets.map { worksheetXML(name: $0.0, rows: $0.1) }.joined()
        return workbookStart + sheetsXML + workbookEnd
    }

    private func buildWorkbookCSV() -> String {
        let worksheets = makeWorksheets()
        var lines: [String] = []

        for (index, worksheet) in worksheets.enumerated() {
            lines.append("# \(worksheet.0)")
            lines.append(contentsOf: worksheet.1.map { row in
                row.map(escapeCSV).joined(separator: ";")
            })
            if index < worksheets.count - 1 {
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    private func buildWorkbookXLSXData() -> Data? {
        let worksheets = makeWorksheets()
        guard !worksheets.isEmpty else { return nil }

        let sheetNames = worksheets.enumerated().map { index, worksheet in
            sanitizeSheetName(worksheet.0, fallback: "Tabelle\(index + 1)")
        }
        let sheetXMLFiles = worksheets.map { worksheet in
            xlsxSheetXML(rows: worksheet.1, sheetName: worksheet.0)
        }

        var workbookSheetsXML: [String] = []
        var workbookRelsXML: [String] = []
        var contentTypeOverrides: [String] = []
        var files: [(String, Data)] = []

        for index in worksheets.indices {
            let sheetId = index + 1
            workbookSheetsXML.append(#"<sheet name="\#(escapeXML(sheetNames[index]))" sheetId="\#(sheetId)" r:id="rId\#(sheetId)"/>"#)
            workbookRelsXML.append(#"<Relationship Id="rId\#(sheetId)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet\#(sheetId).xml"/>"#)
            contentTypeOverrides.append(#"<Override PartName="/xl/worksheets/sheet\#(sheetId).xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>"#)
            files.append(("xl/worksheets/sheet\(sheetId).xml", Data(sheetXMLFiles[index].utf8)))
        }

        let workbookXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>\(workbookSheetsXML.joined())</sheets>
        </workbook>
        """

        let workbookRels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          \(workbookRelsXML.joined())
          <Relationship Id="rId\(worksheets.count + 1)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
        """

        let rootRels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
          <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
        </Relationships>
        """

        let createdAt = iso8601Timestamp(Date())
        let coreXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <dc:creator>Mnemor</dc:creator>
          <cp:lastModifiedBy>Mnemor</cp:lastModifiedBy>
          <dcterms:created xsi:type="dcterms:W3CDTF">\(createdAt)</dcterms:created>
          <dcterms:modified xsi:type="dcterms:W3CDTF">\(createdAt)</dcterms:modified>
        </cp:coreProperties>
        """

        let appXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
          <Application>Mnemor</Application>
          <DocSecurity>0</DocSecurity>
          <ScaleCrop>false</ScaleCrop>
          <HeadingPairs>
            <vt:vector size="2" baseType="variant">
              <vt:variant><vt:lpstr>Worksheets</vt:lpstr></vt:variant>
              <vt:variant><vt:i4>\(worksheets.count)</vt:i4></vt:variant>
            </vt:vector>
          </HeadingPairs>
          <TitlesOfParts>
            <vt:vector size="\(worksheets.count)" baseType="lpstr">\(sheetNames.map { "<vt:lpstr>\(escapeXML($0))</vt:lpstr>" }.joined())</vt:vector>
          </TitlesOfParts>
          <Company></Company>
          <LinksUpToDate>false</LinksUpToDate>
          <SharedDoc>false</SharedDoc>
          <HyperlinksChanged>false</HyperlinksChanged>
          <AppVersion>1.0</AppVersion>
        </Properties>
        """

        let stylesXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="2">
            <font><sz val="11"/><name val="Calibri"/></font>
            <font><b/><sz val="11"/><name val="Calibri"/></font>
          </fonts>
          <fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
          <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
          <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
          <cellXfs count="3">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
            <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
            <xf numFmtId="14" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
          </cellXfs>
          <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
        </styleSheet>
        """

        let contentTypesXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
          <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
          \(contentTypeOverrides.joined())
        </Types>
        """

        files.append(("[Content_Types].xml", Data(contentTypesXML.utf8)))
        files.append(("_rels/.rels", Data(rootRels.utf8)))
        files.append(("docProps/core.xml", Data(coreXML.utf8)))
        files.append(("docProps/app.xml", Data(appXML.utf8)))
        files.append(("xl/workbook.xml", Data(workbookXML.utf8)))
        files.append(("xl/_rels/workbook.xml.rels", Data(workbookRels.utf8)))
        files.append(("xl/styles.xml", Data(stylesXML.utf8)))

        return zipArchiveData(files: files)
    }

    private func xlsxSheetXML(rows: [[String]], sheetName _: String) -> String {
        let headers = rows.first ?? []
        let rowXML = rows.enumerated().map { rowIndex, row in
            let cells = row.enumerated().map { columnIndex, value in
                let cellRef = "\(excelColumnName(for: columnIndex + 1))\(rowIndex + 1)"
                if rowIndex == 0 {
                    return #"<c r="\#(cellRef)" t="inlineStr" s="1"><is><t xml:space="preserve">\#(escapeXML(value))</t></is></c>"#
                }

                let header = columnIndex < headers.count ? headers[columnIndex].lowercased() : ""
                if isDateHeader(header), let serial = excelDateSerial(from: value) {
                    return #"<c r="\#(cellRef)" s="2"><v>\#(serial)</v></c>"#
                }
                if isNumericHeader(header), isNumericValue(value) {
                    return #"<c r="\#(cellRef)"><v>\#(value)</v></c>"#
                }
                return #"<c r="\#(cellRef)" t="inlineStr"><is><t xml:space="preserve">\#(escapeXML(value))</t></is></c>"#
            }.joined()
            return #"<row r="\#(rowIndex + 1)">\#(cells)</row>"#
        }.joined()

        let columnCount = max(rows.map(\.count).max() ?? 1, 1)
        let filterRef = "A1:\(excelColumnName(for: columnCount))\(max(rows.count, 1))"
        let autoFilterXML = rows.isEmpty ? "" : #"<autoFilter ref="\#(filterRef)"/>"#

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetData>\(rowXML)</sheetData>
          \(autoFilterXML)
        </worksheet>
        """
    }

    private func sanitizeSheetName(_ name: String, fallback: String) -> String {
        let invalid = CharacterSet(charactersIn: ":\\\\/?*[]")
        let cleaned = name.unicodeScalars.map { invalid.contains($0) ? "_" : Character($0) }
        let raw = String(cleaned)
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let limited = String((trimmed.isEmpty ? fallback : trimmed).prefix(31))
        return limited.isEmpty ? fallback : limited
    }

    private func excelColumnName(for index: Int) -> String {
        var value = max(index, 1)
        var result = ""
        while value > 0 {
            let remainder = (value - 1) % 26
            result = String(UnicodeScalar(65 + remainder)!) + result
            value = (value - 1) / 26
        }
        return result
    }

    private func isDateHeader(_ header: String) -> Bool {
        let keys = ["datum", "eingang", "fällig", "faellig", "start", "ende"]
        return keys.contains { header.contains($0) }
    }

    private func isNumericHeader(_ header: String) -> Bool {
        let keys = [
            "betrag", "summe", "anzahl", "basiswert", "rechnungen", "offen", "bezahlt",
            "rechnung", "raten", "ausgaben_total", "einnahmen", "prognose", "rate",
            "sollzins_pa", "zins_aktuell", "tilgung_aktuell", "anfangsschuld",
            "restschuld_heute", "restschuld_12m", "tilgung_monat"
        ]
        return keys.contains { header.contains($0) }
    }

    private func isNumericValue(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        return value.range(of: #"^-?\d+(\.\d+)?$"#, options: .regularExpression) != nil
    }

    private func excelDateSerial(from value: String) -> Int? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: value) else { return nil }
        let base = Date(timeIntervalSince1970: -2209161600) // 1900-01-01
        let days = Int(date.timeIntervalSince(base) / 86400)
        return days + 1
    }

    private func iso8601Timestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func zipArchiveData(files: [(String, Data)]) -> Data {
        var data = Data()
        var centralDirectory = Data()
        var localOffsets: [UInt32] = []

        for (path, fileData) in files {
            let pathData = Data(path.utf8)
            let crc = crc32(fileData)
            let localOffset = UInt32(data.count)
            localOffsets.append(localOffset)

            appendUInt32(0x04034b50, to: &data)
            appendUInt16(20, to: &data)
            appendUInt16(0, to: &data)
            appendUInt16(0, to: &data)
            appendUInt16(0, to: &data)
            appendUInt16(0, to: &data)
            appendUInt32(crc, to: &data)
            appendUInt32(UInt32(fileData.count), to: &data)
            appendUInt32(UInt32(fileData.count), to: &data)
            appendUInt16(UInt16(pathData.count), to: &data)
            appendUInt16(0, to: &data)
            data.append(pathData)
            data.append(fileData)
        }

        for ((path, fileData), localOffset) in zip(files, localOffsets) {
            let pathData = Data(path.utf8)
            let crc = crc32(fileData)

            appendUInt32(0x02014b50, to: &centralDirectory)
            appendUInt16(20, to: &centralDirectory)
            appendUInt16(20, to: &centralDirectory)
            appendUInt16(0, to: &centralDirectory)
            appendUInt16(0, to: &centralDirectory)
            appendUInt16(0, to: &centralDirectory)
            appendUInt16(0, to: &centralDirectory)
            appendUInt32(crc, to: &centralDirectory)
            appendUInt32(UInt32(fileData.count), to: &centralDirectory)
            appendUInt32(UInt32(fileData.count), to: &centralDirectory)
            appendUInt16(UInt16(pathData.count), to: &centralDirectory)
            appendUInt16(0, to: &centralDirectory)
            appendUInt16(0, to: &centralDirectory)
            appendUInt16(0, to: &centralDirectory)
            appendUInt16(0, to: &centralDirectory)
            appendUInt32(0, to: &centralDirectory)
            appendUInt32(localOffset, to: &centralDirectory)
            centralDirectory.append(pathData)
        }

        let centralStart = UInt32(data.count)
        data.append(centralDirectory)
        let centralSize = UInt32(centralDirectory.count)

        appendUInt32(0x06054b50, to: &data)
        appendUInt16(0, to: &data)
        appendUInt16(0, to: &data)
        appendUInt16(UInt16(files.count), to: &data)
        appendUInt16(UInt16(files.count), to: &data)
        appendUInt32(centralSize, to: &data)
        appendUInt32(centralStart, to: &data)
        appendUInt16(0, to: &data)

        return data
    }

    private func appendUInt16(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0x00ff))
        data.append(UInt8((value & 0xff00) >> 8))
    }

    private func appendUInt32(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0x000000ff))
        data.append(UInt8((value & 0x0000ff00) >> 8))
        data.append(UInt8((value & 0x00ff0000) >> 16))
        data.append(UInt8((value & 0xff000000) >> 24))
    }

    private func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffffffff
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                let mask: UInt32 = (crc & 1) != 0 ? 0xedb88320 : 0x00000000
                crc = (crc >> 1) ^ mask
            }
        }
        return ~crc
    }

    private func worksheetXML(name: String, rows: [[String]]) -> String {
        let rowsXML = rows.map { row in
            let cells = row.map { "<Cell><Data ss:Type=\"String\">\(escapeXML($0))</Data></Cell>" }.joined()
            return "<Row>\(cells)</Row>"
        }.joined()
        return "<Worksheet ss:Name=\"\(escapeXML(name))\"><Table>\(rowsXML)</Table></Worksheet>"
    }

    private func escapeXML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(";") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    private func numberString(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private var planningBaseBalance: Double {
        effectiveUseCurrentBalance ? currentBalance : startBalance
    }

    private var effectiveUseCurrentBalance: Bool {
        currentBalance != 0 || useCurrentBalance
    }

    private var sortedIncomeEntries: [IncomeEntry] {
        incomeEntries.sorted { lhs, rhs in
            if lhs.isActive != rhs.isActive { return lhs.isActive && !rhs.isActive }
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func normalizeInstallmentTypeFlagsIfNeeded() {
        var changed = false
        for plan in installmentPlans {
            guard plan.isLoanFlag == nil else { continue }
            let inferredLoan =
                InstallmentPlan.Kind(rawValue: plan.kindRaw) == .loan ||
                (plan.loanRepaymentModeRaw.flatMap { InstallmentPlan.LoanRepaymentMode(rawValue: $0) } != nil) ||
                plan.initialPrincipal != nil ||
                plan.annualInterestRatePercent != nil ||
                plan.monthlyInterest > 0
            plan.isLoanFlag = inferredLoan
            if plan.kindRaw.isEmpty {
                plan.kindRaw = inferredLoan ? InstallmentPlan.Kind.loan.rawValue : InstallmentPlan.Kind.fixedCost.rawValue
            }
            changed = true
        }
        if changed {
            try? modelContext.save()
        }
    }

    private func addInstallmentPlan(forceKind: InstallmentPlan.Kind? = nil) {
        let kindToSave = forceKind ?? installmentKind
        let trimmed = installmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let payment = installmentMonthlyPayment, payment > 0 else { return }
        installmentValidationMessage = nil
        if kindToSave == .loan, installmentLoanRepaymentMode == .fixedPrincipal {
            guard let rate = installmentAnnualInterestRate, rate > 0 else {
                installmentValidationMessage = L10n.t("Bitte Sollzins p.a. für feste Tilgung eingeben.", "Please enter nominal interest p.a. for fixed principal mode.")
                return
            }
        }
        let interest: Decimal = .zero
        let endDate = installmentHasEndDate ? installmentEndDate : nil

        let plan = InstallmentPlan(
            kind: kindToSave,
            name: trimmed,
            monthlyPayment: payment,
            monthlyInterest: max(Decimal.zero, interest),
            annualInterestRatePercent: kindToSave == .loan ? installmentAnnualInterestRate : nil,
            initialPrincipal: kindToSave == .loan ? installmentInitialPrincipal : nil,
            loanRepaymentMode: kindToSave == .loan ? installmentLoanRepaymentMode : .annuity,
            startDate: installmentStartDate,
            endDate: endDate,
            paymentDay: installmentPaymentDay,
            isActive: true
        )
        modelContext.insert(plan)
        // Explicitly re-apply to ensure persisted type flags are consistent immediately.
        plan.kind = kindToSave
        plan.loanRepaymentMode = kindToSave == .loan ? installmentLoanRepaymentMode : .annuity
        try? modelContext.save()

        installmentName = ""
        installmentKind = .fixedCost
        installmentLoanRepaymentMode = .annuity
        installmentMonthlyPayment = nil
        installmentMonthlyInterest = nil
        installmentAnnualInterestRate = nil
        installmentInitialPrincipal = nil
        installmentStartDate = Date()
        installmentHasEndDate = false
        installmentEndDate = Date()
        installmentPaymentDay = 1
        installmentValidationMessage = nil
        refreshExportFile()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func beginEditingInstallmentPlan(_ plan: InstallmentPlan, forcedKind: InstallmentPlan.Kind? = nil) {
        editingInstallmentPlan = plan
        // Keep edit mode aligned with the tapped row badge/source.
        editContextKind = forcedKind ?? resolvedInstallmentKind(for: plan)
        applyInstallmentEditState(from: plan)
        isShowingEditInstallmentSheet = true
    }

    private func beginSpecialRepayment(for plan: InstallmentPlan) {
        guard resolvedInstallmentKind(for: plan) == .loan else { return }
        editSpecialRepaymentAmountText = ""
        editSpecialRepaymentDate = Date()
        specialRepaymentPlanForSheet = plan
    }

    private func applyInstallmentEditState(from plan: InstallmentPlan) {
        editInstallmentName = plan.name
        editInstallmentKind = editContextKind
        editInstallmentLoanRepaymentMode = editContextKind == .loan ? resolvedLoanRepaymentMode(for: plan) : .annuity
        editInstallmentMonthlyPayment = plan.monthlyPayment
        editInstallmentMonthlyInterest = plan.monthlyInterest
        editInstallmentAnnualInterestRate = plan.annualInterestRatePercent
        editInstallmentInitialPrincipal = plan.initialPrincipal
        editInstallmentStartDate = plan.startDate
        editInstallmentValidationMessage = nil
        if let endDate = plan.endDate {
            editInstallmentHasEndDate = true
            editInstallmentEndDate = endDate
        } else {
            editInstallmentHasEndDate = false
            editInstallmentEndDate = Date()
        }
        editInstallmentPaymentDay = plan.paymentDay
        editSpecialRepaymentAmountText = ""
        editSpecialRepaymentDate = Date()
        // Self-heal potential inconsistent raw fields from older or transient records.
        if plan.kindRaw != editContextKind.rawValue {
            plan.kind = editContextKind
            if editContextKind == .loan {
                plan.loanRepaymentMode = editInstallmentLoanRepaymentMode
            }
            try? modelContext.save()
        }
    }

    private func resolvedInstallmentKind(for plan: InstallmentPlan) -> InstallmentPlan.Kind {
        if let isLoan = plan.isLoanFlag {
            return isLoan ? .loan : .fixedCost
        }
        if let parsed = InstallmentPlan.Kind(rawValue: plan.kindRaw) {
            return parsed
        }
        if let raw = plan.loanRepaymentModeRaw,
           InstallmentPlan.LoanRepaymentMode(rawValue: raw) != nil {
            return .loan
        }
        if plan.initialPrincipal != nil || plan.annualInterestRatePercent != nil || plan.monthlyInterest > 0 {
            return .loan
        }
        return .fixedCost
    }

    private func resolvedLoanRepaymentMode(for plan: InstallmentPlan) -> InstallmentPlan.LoanRepaymentMode {
        if let raw = plan.loanRepaymentModeRaw,
           let parsed = InstallmentPlan.LoanRepaymentMode(rawValue: raw) {
            return parsed
        }
        return .annuity
    }

    private func saveEditedInstallmentPlan() {
        guard let plan = editingInstallmentPlan else { return }
        let kindToSave = editContextKind
        let trimmed = editInstallmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let payment = editInstallmentMonthlyPayment,
              payment > 0
        else { return }
        editInstallmentValidationMessage = nil
        if kindToSave == .loan, editInstallmentLoanRepaymentMode == .fixedPrincipal {
            guard let rate = editInstallmentAnnualInterestRate, rate > 0 else {
                editInstallmentValidationMessage = L10n.t("Bitte Sollzins p.a. für feste Tilgung eingeben.", "Please enter nominal interest p.a. for fixed principal mode.")
                return
            }
        }

        plan.name = trimmed
        plan.kind = kindToSave
        plan.monthlyPayment = payment
        if kindToSave == .loan {
            plan.loanRepaymentMode = editInstallmentLoanRepaymentMode
            if editInstallmentLoanRepaymentMode == .fixedPrincipal {
                plan.monthlyInterest = 0
                plan.annualInterestRatePercent = editInstallmentAnnualInterestRate
            } else {
                plan.monthlyInterest = 0
                plan.annualInterestRatePercent = editInstallmentAnnualInterestRate
            }
            plan.initialPrincipal = editInstallmentInitialPrincipal
        } else {
            plan.loanRepaymentMode = .annuity
            plan.monthlyInterest = 0
            plan.annualInterestRatePercent = nil
            plan.initialPrincipal = nil
        }
        plan.startDate = editInstallmentStartDate
        plan.endDate = editInstallmentHasEndDate ? editInstallmentEndDate : nil
        plan.paymentDay = min(max(editInstallmentPaymentDay, 1), 28)

        try? modelContext.save()
        refreshExportFile()
        editInstallmentValidationMessage = nil
        isShowingEditInstallmentSheet = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func rateSubtitle(_ plan: InstallmentPlan) -> String {
        let start = dateString(plan.startDate)
        let end = plan.endDate.map(dateString) ?? L10n.t("offen", "open-ended")
        let from = L10n.t("ab", "from")
        let endLabel = L10n.t("Ende", "end")
        let dayLabel = L10n.t("am", "on day")
        let scheduleLine = "\(from) \(start), \(endLabel) \(end), \(dayLabel) \(plan.paymentDay)."
        if plan.kind == .fixedCost {
            return scheduleLine
        }
        let repaymentText = plan.loanRepaymentMode == .fixedPrincipal
            ? L10n.t("Feste Tilgung", "Fixed principal")
            : L10n.t("Annuität", "Annuity")
        let interestLabel = L10n.t("Sollzins", "Nominal interest")
        let rateText = plan.loanRepaymentMode == .fixedPrincipal
            ? (plan.annualInterestRatePercent.map { "\(interestLabel) \($0.formatted(.number.precision(.fractionLength(2))))% p.a." } ?? L10n.t("Sollzins fehlt", "Nominal interest missing"))
            : (plan.annualInterestRatePercent.map { "\(interestLabel) \($0.formatted(.number.precision(.fractionLength(2))))% p.a." } ?? L10n.t("feste Monatsrate", "fixed monthly payment"))
        return "\(scheduleLine) · \(repaymentText) · \(rateText)"
    }

    private func remainingPrincipal(of plan: InstallmentPlan, at referenceDate: Date) -> Decimal? {
        guard plan.kind == .loan else { return nil }
        guard let initial = plan.initialPrincipal else { return nil }
        var remaining = initial
        for (index, dueDate) in installmentDueDates(for: plan, upTo: referenceDate).enumerated() {
            guard index < 1200 else { break }
            let split = installmentSplit(plan: plan, remainingBefore: remaining)
            remaining = max(Decimal.zero, remaining - split.principal)
            if remaining <= 0 { break }
            if let endDate = plan.endDate, dueDate > calendar.startOfDay(for: endDate) { break }
        }
        return remaining
    }

    private func installmentDueDates(for plan: InstallmentPlan, upTo referenceDate: Date) -> [Date] {
        let reference = calendar.startOfDay(for: referenceDate)
        let start = calendar.startOfDay(for: plan.startDate)
        guard reference >= start else { return [] }

        var dueDates: [Date] = []
        var cursor = startOfMonth(for: start)
        while cursor <= reference {
            if let monthInterval = calendar.dateInterval(of: .month, for: cursor) {
                let dayRange = calendar.range(of: .day, in: .month, for: cursor) ?? 1..<29
                let day = min(max(plan.paymentDay, 1), dayRange.count)
                if let payoutDate = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                    if payoutDate >= start && payoutDate <= reference {
                        if let endDate = plan.endDate, payoutDate > calendar.startOfDay(for: endDate) {
                            break
                        }
                        dueDates.append(payoutDate)
                    }
                }
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return dueDates
    }

    private func installmentSplit(plan: InstallmentPlan, remainingBefore: Decimal?) -> (interest: Decimal, principal: Decimal) {
        let baseAmount = max(Decimal.zero, plan.monthlyPayment)
        guard plan.kind == .loan else {
            return (0, baseAmount)
        }
        let computedInterest: Decimal = {
            if let rate = plan.annualInterestRatePercent, let remainingBefore {
                let monthly = remainingBefore * rate / Decimal(100) / Decimal(12)
                return max(Decimal.zero, monthly)
            }
            return max(Decimal.zero, plan.monthlyInterest)
        }()

        switch plan.loanRepaymentMode {
        case .annuity:
            let cappedInterest = min(baseAmount, computedInterest)
            let principal = max(Decimal.zero, baseAmount - cappedInterest)
            return (cappedInterest, principal)
        case .fixedPrincipal:
            let desiredPrincipal = baseAmount
            let principal = max(Decimal.zero, min(desiredPrincipal, remainingBefore ?? desiredPrincipal))
            return (max(Decimal.zero, computedInterest), principal)
        }
    }

    private func remainingPrincipalBeforeDue(of plan: InstallmentPlan, dueDate: Date) -> Decimal? {
        guard plan.kind == .loan else { return nil }
        guard let initial = plan.initialPrincipal else { return nil }

        let dueDay = calendar.startOfDay(for: dueDate)
        guard let dayBeforeDue = calendar.date(byAdding: .day, value: -1, to: dueDay) else {
            return initial
        }

        var remaining = initial
        for (index, paidDate) in installmentDueDates(for: plan, upTo: dayBeforeDue).enumerated() {
            guard index < 1200 else { break }
            let split = installmentSplit(plan: plan, remainingBefore: remaining)
            remaining = max(Decimal.zero, remaining - split.principal)
            if remaining <= 0 { break }
            if let endDate = plan.endDate, paidDate > calendar.startOfDay(for: endDate) { break }
        }

        let specialRepaymentsTotal = specialRepaymentTotal(for: plan, upTo: dayBeforeDue)
        remaining = max(Decimal.zero, remaining - specialRepaymentsTotal)
        return remaining
    }

    private func installmentTotalAmount(for plan: InstallmentPlan, dueDate: Date) -> Decimal {
        if let endDate = plan.endDate, calendar.startOfDay(for: dueDate) > calendar.startOfDay(for: endDate) {
            return 0
        }
        if plan.kind == .fixedCost {
            return plan.monthlyPayment
        }
        let remainingBefore = remainingPrincipalBeforeDue(of: plan, dueDate: dueDate)
        if let remainingBefore, remainingBefore <= 0 {
            return 0
        }
        let split = installmentSplit(plan: plan, remainingBefore: remainingBefore)
        return split.interest + split.principal
    }

    private func currentInstallmentSplit(for plan: InstallmentPlan) -> (interest: Decimal, principal: Decimal) {
        if let endDate = plan.endDate, calendar.startOfDay(for: Date()) > calendar.startOfDay(for: endDate) {
            return (0, 0)
        }
        let remainingBefore = remainingPrincipalBeforeDue(of: plan, dueDate: Date())
        if plan.kind == .loan, let remainingBefore, remainingBefore <= 0 {
            return (0, 0)
        }
        return installmentSplit(plan: plan, remainingBefore: remainingBefore)
    }

    private func currentInstallmentTotal(for plan: InstallmentPlan) -> Decimal {
        installmentTotalAmount(for: plan, dueDate: Date())
    }

    private func specialRepaymentTotal(for plan: InstallmentPlan, upTo referenceDate: Date) -> Decimal {
        let ref = calendar.startOfDay(for: referenceDate)
        return specialRepayments
            .filter { $0.planID == plan.id && calendar.startOfDay(for: $0.repaymentDate) <= ref }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private func remainingPrincipalAfterSpecialRepayments(of plan: InstallmentPlan, at referenceDate: Date) -> Decimal? {
        guard let base = remainingPrincipal(of: plan, at: referenceDate) else { return nil }
        let adjusted = base - specialRepaymentTotal(for: plan, upTo: referenceDate)
        return max(adjusted, 0)
    }

    private func addSpecialRepayment(to plan: InstallmentPlan) {
        guard plan.kind == .loan,
              let rawAmount = parsedSpecialRepaymentAmount(),
              rawAmount > 0
        else { return }

        let cappedAmount: Decimal
        if let remaining = remainingPrincipalAfterSpecialRepayments(of: plan, at: editSpecialRepaymentDate), remaining > 0 {
            cappedAmount = min(rawAmount, remaining)
        } else if remainingPrincipalAfterSpecialRepayments(of: plan, at: editSpecialRepaymentDate) == 0 {
            return
        } else {
            cappedAmount = rawAmount
        }

        let repayment = InstallmentSpecialRepayment(
            planID: plan.id,
            amount: cappedAmount,
            repaymentDate: editSpecialRepaymentDate
        )
        modelContext.insert(repayment)
        try? modelContext.save()

        editSpecialRepaymentAmountText = ""
        editSpecialRepaymentDate = Date()
        refreshExportFile()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func parsedSpecialRepaymentAmount() -> Decimal? {
        let raw = editSpecialRepaymentAmountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "EUR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "\u{00a0}", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard !raw.isEmpty else { return nil }

        if raw.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            return Decimal(string: raw)
        }

        let lastComma = raw.lastIndex(of: ",")
        let lastDot = raw.lastIndex(of: ".")

        let normalized: String
        if let comma = lastComma, let dot = lastDot {
            if comma > dot {
                normalized = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                normalized = raw.replacingOccurrences(of: ",", with: "")
            }
        } else if lastComma != nil {
            normalized = raw.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
        } else {
            normalized = raw.replacingOccurrences(of: ",", with: "")
        }

        return Decimal(string: normalized)
    }
}

private struct IncomeManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var incomeEntries: [IncomeEntry]
    private let calendar = Calendar.current

    @State private var incomeName: String = ""
    @State private var incomeAmount: Decimal?
    @State private var incomeKind: IncomeEntry.Kind = .monthlyFixed
    @State private var incomeStartDate: Date = Date()
    @State private var incomeMonthlyDay: Int = 1
    @State private var editingIncomeEntry: IncomeEntry?
    @State private var editIncomeName: String = ""
    @State private var editIncomeKind: IncomeEntry.Kind = .monthlyFixed
    @State private var editIncomeAmount: Decimal?
    @State private var editIncomeStartDate: Date = Date()
    @State private var editIncomeMonthlyDay: Int = 1
    @State private var isShowingEditIncomeSheet = false
    @FocusState private var isAmountFieldFocused: Bool
    // See StatsView: observe so the view re-renders on language toggle.
    @AppStorage(AppSettings.appLanguageCodeKey) private var appLanguageCode: String = AppSettings.appLanguageCode

    var body: some View {
        VStack(spacing: 0) {
            AppHeroHeader(
                title: L10n.t("Einnahmen", "Income"),
                subtitle: L10n.t("Fixe und variable Einnahmen verwalten", "Manage fixed and variable income"),
                icon: "banknote.fill"
            )

            Form {
            Section(L10n.t("Neue Einnahme", "New income")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t("Bezeichnung", "Name"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField(L10n.t("z. B. Gehalt", "e.g. Salary"), text: $incomeName)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t("Betrag", "Amount"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField(L10n.t("z. B. 2800,00", "e.g. 2800.00"), value: $incomeAmount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .focused($isAmountFieldFocused)
                }
                Picker(L10n.t("Typ", "Type"), selection: $incomeKind) {
                    ForEach(IncomeEntry.Kind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                DatePicker(
                    incomeKind == .monthlyFixed
                        ? L10n.t("Ab (Monat/Jahr)", "From (month/year)")
                        : L10n.t("Datum", "Date"),
                    selection: $incomeStartDate,
                    displayedComponents: .date
                )
                if incomeKind == .monthlyFixed {
                    Stepper(
                        "\(L10n.t("Monatstag", "Day of month")): \(incomeMonthlyDay).",
                        value: $incomeMonthlyDay,
                        in: 1...31
                    )
                }
                Button(L10n.t("Einnahme speichern", "Save income")) {
                    addIncomeEntry()
                }
                .buttonStyle(.borderedProminent)
            }

            Section(L10n.t("Einnahmen (Fix + Variabel)", "Income (fixed + variable)")) {
                if sortedIncomeEntries.isEmpty {
                    Text(L10n.t("Keine Einnahmen hinterlegt.", "No income entries added."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedIncomeEntries) { income in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(income.name)
                                    .font(.headline.weight(.semibold))
                                Text(L10n.isEnglish ? "\(income.kind.title) · from \(income.startDate.formatted(.dateTime.day().month().year()))" : "\(income.kind.title) · ab \(income.startDate.formatted(.dateTime.day().month().year()))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(income.amount.formatted(.currency(code: "EUR")))
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        .swipeActions {
                            Button {
                                beginEditingIncome(income)
                            } label: {
                                Text(L10n.t("Bearbeiten", "Edit"))
                            }
                            .tint(AppTheme.accent)
                            Button(role: .destructive) {
                                modelContext.delete(income)
                                do {
                                    try modelContext.save()
                                } catch {
                                    NSLog("Mnemor: delete income failed: \(error.localizedDescription)")
                                }
                            } label: {
                                Text(L10n.t("Löschen", "Delete"))
                            }
                        }
                    }
                }
            }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .tint(AppTheme.accent)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.t("Fertig", "Done")) {
                    isAmountFieldFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .sheet(isPresented: $isShowingEditIncomeSheet) {
            NavigationStack {
                Form {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.t("Bezeichnung", "Name"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField(L10n.t("z. B. Gehalt", "e.g. Salary"), text: $editIncomeName)
                    }
                    Picker(L10n.t("Typ", "Type"), selection: $editIncomeKind) {
                        ForEach(IncomeEntry.Kind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.t("Betrag", "Amount"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField(L10n.t("z. B. 2800,00", "e.g. 2800.00"), value: $editIncomeAmount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .focused($isAmountFieldFocused)
                    }
                    DatePicker(editIncomeDateLabel, selection: $editIncomeStartDate, displayedComponents: .date)
                    if editIncomeKind == .monthlyFixed {
                        Stepper(
                            "\(L10n.t("Monatstag", "Day of month")): \(editIncomeMonthlyDay).",
                            value: $editIncomeMonthlyDay,
                            in: 1...31
                        )
                    }
                }
                .navigationTitle(L10n.t("Einnahme bearbeiten", "Edit income"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.t("Abbrechen", "Cancel")) {
                            isShowingEditIncomeSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.t("Speichern", "Save")) {
                            saveEditedIncome()
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(L10n.t("Fertig", "Done")) {
                            isAmountFieldFocused = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            }
        }
    }

    private var sortedIncomeEntries: [IncomeEntry] {
        incomeEntries.sorted { lhs, rhs in
            if lhs.isActive != rhs.isActive { return lhs.isActive && !rhs.isActive }
            if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func addIncomeEntry() {
        let trimmed = incomeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let amount = incomeAmount, amount > 0 else { return }

        if incomeKind == .monthlyFixed,
           let existing = incomeEntries.first(where: {
               $0.kind == .monthlyFixed &&
               $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
           }) {
            existing.name = trimmed
            existing.amount = amount
            existing.startDate = normalizedMonthlyIncomeStartDate(baseDate: incomeStartDate, day: incomeMonthlyDay)
            existing.isActive = true
        } else {
            let entry = IncomeEntry(
                name: trimmed,
                amount: amount,
                kind: incomeKind,
                startDate: incomeKind == .monthlyFixed
                    ? normalizedMonthlyIncomeStartDate(baseDate: incomeStartDate, day: incomeMonthlyDay)
                    : incomeStartDate,
                isActive: true
            )
            modelContext.insert(entry)
        }

        try? modelContext.save()
        incomeName = ""
        incomeAmount = nil
        incomeKind = .monthlyFixed
        incomeStartDate = Date()
        incomeMonthlyDay = 1
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var editIncomeDateLabel: String {
        if editIncomeKind == .monthlyFixed {
            return L10n.t("Ab (Monat/Jahr)", "From (month/year)")
        }
        return L10n.t("Datum", "Date")
    }

    private func beginEditingIncome(_ income: IncomeEntry) {
        editingIncomeEntry = income
        editIncomeName = income.name
        editIncomeKind = income.kind
        editIncomeAmount = income.amount
        editIncomeStartDate = income.startDate
        editIncomeMonthlyDay = calendar.component(.day, from: income.startDate)
        isShowingEditIncomeSheet = true
    }

    private func saveEditedIncome() {
        let trimmedName = editIncomeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let income = editingIncomeEntry,
              !trimmedName.isEmpty,
              let amount = editIncomeAmount,
              amount > 0
        else { return }

        income.name = trimmedName
        income.kind = editIncomeKind
        income.amount = amount
        income.startDate = editIncomeKind == .monthlyFixed
            ? normalizedMonthlyIncomeStartDate(baseDate: editIncomeStartDate, day: editIncomeMonthlyDay)
            : editIncomeStartDate
        try? modelContext.save()
        isShowingEditIncomeSheet = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func normalizedMonthlyIncomeStartDate(baseDate: Date, day: Int) -> Date {
        let year = calendar.component(.year, from: baseDate)
        let month = calendar.component(.month, from: baseDate)
        let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? baseDate
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<29
        let validDay = min(max(day, 1), range.count)
        let normalized = calendar.date(from: DateComponents(year: year, month: month, day: validDay)) ?? baseDate
        return calendar.startOfDay(for: normalized)
    }
}

private struct VendorRow: Identifiable {
    let vendor: String
    let total: Decimal
    let count: Int

    var id: String { vendor }
}

private struct MonthlyInstallmentOccurrence: Identifiable {
    let id = UUID()
    let planName: String
    let dueDate: Date
    let amount: Decimal
    let isOpen: Bool
}

private struct WeeklyLiquidityRow: Identifiable {
    let id = UUID()
    let weekStart: Date
    let label: String
    let income: Double
    let invoiceOutgoing: Double
    let installmentOutgoing: Double
    let totalOutgoing: Double
    let projectedBalance: Double
    let categoryBreakdown: [BreakdownItem]
}

private struct BreakdownItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}

private struct WeeklyCashflowBar: Identifiable {
    let id = UUID()
    let weekStart: Date
    let type: String
    let amount: Double
}

private struct CategoryRow: Identifiable {
    let name: String
    let amount: Decimal
    let count: Int

    var id: String { name }
}
