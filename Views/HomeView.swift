import SwiftUI
import SwiftData
import Charts
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var invoices: [Invoice]
    @Query private var incomeEntries: [IncomeEntry]
    @Query private var installmentPlans: [InstallmentPlan]
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var scanViewModel = ScanViewModel()

    @State private var showScanner = false
    @State private var showReview = false
    @State private var showPDFImporter = false
    @State private var showQuickScanOptions = false
    @State private var scanCaptureMode: ScanCaptureMode = .invoice

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        dashboardCard(
                            title: "Fällig in 7 Tagen",
                            value: "\(dueInNext7DaysCount)",
                            symbol: "calendar.badge.clock",
                            tint: .orange
                        )
                        dashboardCard(
                            title: "Überfällig",
                            value: "\(overdueCount)",
                            symbol: "exclamationmark.triangle.fill",
                            tint: .red
                        )
                        dashboardCard(
                            title: "Kontostand in 30 Tagen",
                            value: projectedBalance30Days.formatted(.currency(code: "EUR")),
                            symbol: "chart.line.uptrend.xyaxis",
                            tint: .blue
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 4)

                Picker("Filter", selection: $viewModel.filter) {
                    ForEach(InvoiceFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                let filtered = viewModel.filtered(invoices)
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Rechnungen",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Tippe auf Scannen, fotografiere eine Rechnung und prüfe die erkannten Felder.")
                    )
                } else {
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
                }
            }
            .background(warmBackground.ignoresSafeArea())
            .navigationTitle("Rechnungen")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color(red: 0.54, green: 0.35, blue: 0.25))
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Text("Rechnungen")
                        .fontWeight(.semibold)
                    NavigationLink("Ausgaben") {
                        StatsView(mode: .expenses)
                    }
                    NavigationLink("Auswertung") {
                        StatsView(mode: .reports)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink("Einnahmen") {
                            IncomeManagementView()
                        }
                        NavigationLink("Settings") {
                            SettingsView()
                        }
                        NavigationLink("Feedback") {
                            FeedbackView()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Scan") {
                        showQuickScanOptions = true
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(background: Color(red: 0.31, green: 0.42, blue: 0.56), foreground: .white))

                    Button("Manuell") {
                        scanViewModel.prepareManualEntry()
                        showReview = true
                    }
                    .buttonStyle(WarmPrimaryButtonStyle(background: Color(red: 0.13, green: 0.22, blue: 0.33), foreground: .white))
                }
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial.opacity(0.001))
            }
            .confirmationDialog("Scan wählen", isPresented: $showQuickScanOptions) {
                Button("Scan Rechnung") {
                    scanCaptureMode = .invoice
                    showScanner = true
                }
                Button("Scan Kassenbon") {
                    scanCaptureMode = .receipt
                    showScanner = true
                }
                Button("PDF Import") {
                    showPDFImporter = true
                }
                Button("Abbrechen", role: .cancel) {}
            }
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
                    ContentUnavailableView("Kamera nicht verfügbar", systemImage: "camera.fill")
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
        }
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

    private var dueInNext7DaysCount: Int {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        return invoices.filter { invoice in
            guard invoice.status == .open, let due = invoice.dueDate else { return false }
            let day = Calendar.current.startOfDay(for: due)
            return day >= start && day <= end
        }.count
    }

    private var overdueCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return invoices.filter { invoice in
            guard invoice.status == .open, let due = invoice.dueDate else { return false }
            return Calendar.current.startOfDay(for: due) < today
        }.count
    }

    private var projectedBalance30Days: Double {
        let defaults = UserDefaults.standard
        let useCurrentBalance = defaults.bool(forKey: "liquidity.useCurrentBalance")
        let currentBalance = defaults.double(forKey: "liquidity.currentBalance")
        let startBalance = defaults.double(forKey: "liquidity.startBalance")
        let effectiveUseCurrentBalance = currentBalance != 0 || useCurrentBalance
        let base = effectiveUseCurrentBalance ? currentBalance : startBalance
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today

        let invoiceOutgoing = invoices.reduce(0.0) { partial, invoice in
            guard invoice.status == .open, let due = invoice.dueDate else { return partial }
            let day = Calendar.current.startOfDay(for: due)
            guard day >= today && day <= end else { return partial }
            return partial + (invoice.amount.map { NSDecimalNumber(decimal: $0).doubleValue } ?? 0)
        }

        let installmentOutgoing = installmentPlans
            .filter(\.isActive)
            .reduce(0.0) { partial, plan in
                partial + projectedInstallmentAmount(for: plan, start: today, endInclusive: end)
            }

        let incomeIncoming = incomeEntries
            .filter(\.isActive)
            .reduce(0.0) { partial, income in
                partial + projectedIncomeAmount(for: income, start: today, endInclusive: end)
            }

        return base + incomeIncoming - invoiceOutgoing - installmentOutgoing
    }

    private func projectedInstallmentAmount(for plan: InstallmentPlan, start: Date, endInclusive: Date) -> Double {
        let calendar = Calendar.current
        guard start <= endInclusive else { return 0 }
        let planStart = calendar.startOfDay(for: plan.startDate)
        let planEnd = plan.endDate.map { calendar.startOfDay(for: $0) }
        let monthAnchors = projectedUniqueMonthsBetween(start: start, endInclusive: endInclusive)
        var total = 0.0

        for monthAnchor in monthAnchors {
            guard let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor) else { continue }
            let dayRange = calendar.range(of: .day, in: .month, for: monthAnchor) ?? 1..<29
            let paymentDay = min(max(plan.paymentDay, 1), dayRange.count)
            guard let paymentDate = calendar.date(byAdding: .day, value: paymentDay - 1, to: monthInterval.start) else { continue }
            let due = calendar.startOfDay(for: paymentDate)
            guard due >= start && due <= endInclusive else { continue }
            guard due >= planStart else { continue }
            if let planEnd, due > planEnd { continue }
            total += NSDecimalNumber(decimal: plan.monthlyPayment).doubleValue
        }
        return total
    }

    private func projectedIncomeAmount(for income: IncomeEntry, start: Date, endInclusive: Date) -> Double {
        let calendar = Calendar.current
        guard start <= endInclusive else { return 0 }
        switch income.kind {
        case .oneTime:
            let day = calendar.startOfDay(for: income.startDate)
            guard day >= start && day <= endInclusive else { return 0 }
            return NSDecimalNumber(decimal: income.amount).doubleValue
        case .monthlyFixed:
            let monthAnchors = projectedUniqueMonthsBetween(start: start, endInclusive: endInclusive)
            let dayOfMonth = calendar.component(.day, from: income.startDate)
            var total = 0.0
            for monthAnchor in monthAnchors {
                guard let interval = calendar.dateInterval(of: .month, for: monthAnchor) else { continue }
                let dayRange = calendar.range(of: .day, in: .month, for: monthAnchor) ?? 1..<29
                let targetDay = min(dayOfMonth, dayRange.count)
                guard let payoutDate = calendar.date(byAdding: .day, value: targetDay - 1, to: interval.start) else { continue }
                let payout = calendar.startOfDay(for: payoutDate)
                guard payout >= start && payout <= endInclusive else { continue }
                guard payout >= calendar.startOfDay(for: income.startDate) else { continue }
                total += NSDecimalNumber(decimal: income.amount).doubleValue
            }
            return total
        }
    }

    private func projectedUniqueMonthsBetween(start: Date, endInclusive: Date) -> [Date] {
        let calendar = Calendar.current
        guard start <= endInclusive else { return [] }
        var months: [Date] = []
        var current = startOfMonth(start)
        let endMonth = startOfMonth(endInclusive)
        while current <= endMonth {
            months.append(current)
            guard let next = calendar.date(byAdding: .month, value: 1, to: current) else { break }
            current = next
        }
        return months
    }

    private func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    private var duplicateInvoiceIDs: Set<UUID> {
        var groups: [String: [UUID]] = [:]
        for invoice in invoices {
            let vendor = invoice.vendorName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let number = (invoice.invoiceNumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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

    private func dashboardCard(title: String, value: String, symbol: String, tint: Color) -> some View {
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

private struct WarmPrimaryButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .font(.title3.weight(.medium))
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(background.opacity(configuration.isPressed ? 0.85 : 1))
            )
            .foregroundStyle(foreground)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

private struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    enum Mode {
        case expenses
        case reports
    }

    enum DataScope: String, CaseIterable, Identifiable {
        case open = "Nur offen"
        case all = "Alle"

        var id: String { rawValue }
    }

    enum StatsTab: String, CaseIterable, Identifiable {
        case analysis = "Übersicht"
        case fixedCosts = "Fixkosten"

        var id: String { rawValue }
    }

    enum ReportsTab: String, CaseIterable, Identifiable {
        case total = "Gesamt"
        case invoices = "Rechnungen"

        var id: String { rawValue }
    }

    enum ReportInvoiceStatusScope: String, CaseIterable, Identifiable {
        case open = "Offen"
        case paid = "Bezahlt"
        case all = "Alle"

        var id: String { rawValue }
    }

    enum FixedCostsTab: String, CaseIterable, Identifiable {
        case installments = "Raten"
        case debt = "Restschuld"

        var id: String { rawValue }
    }

    @Query private var invoices: [Invoice]
    @Query private var incomeEntries: [IncomeEntry]
    @Query private var installmentPlans: [InstallmentPlan]
    @Query private var specialRepayments: [InstallmentSpecialRepayment]
    @State private var mode: Mode = .reports
    @State private var selectedTab: StatsTab = .analysis
    @State private var selectedReportsTab: ReportsTab = .total
    @State private var selectedFixedCostsTab: FixedCostsTab = .installments
    @State private var selectedMonth: Date = Date()
    @State private var dataScope: DataScope = .open
    @State private var reportInvoiceStatusScope: ReportInvoiceStatusScope = .all
    @AppStorage(AppSettings.exportFormatKey) private var exportFormat: String = AppSettings.exportFormat
    @AppStorage("liquidity.startBalance") private var startBalance: Double = 0
    @AppStorage("liquidity.useCurrentBalance") private var useCurrentBalance: Bool = false
    @AppStorage("liquidity.currentBalance") private var currentBalance: Double = 0
    @AppStorage(AppSettings.negativeCashflowAlertEnabledKey) private var negativeCashflowAlertEnabled: Bool = AppSettings.negativeCashflowAlertEnabled
    @AppStorage(AppSettings.negativeCashflowAlertWeeksKey) private var negativeCashflowAlertWeeks: Int = AppSettings.negativeCashflowAlertWeeks
    @State private var exportURL: URL?
    @State private var exportStatusMessage: String?
    @State private var installmentName: String = ""
    @State private var installmentMonthlyPayment: Decimal?
    @State private var installmentMonthlyInterest: Decimal?
    @State private var installmentAnnualInterestRate: Decimal?
    @State private var installmentInitialPrincipal: Decimal?
    @State private var installmentStartDate: Date = Date()
    @State private var installmentHasEndDate: Bool = false
    @State private var installmentEndDate: Date = Date()
    @State private var installmentPaymentDay: Int = 1
    @State private var selectedRepaymentPlanID: UUID?
    @State private var specialRepaymentAmount: Decimal?
    @State private var specialRepaymentDate: Date = Date()
    @State private var editingInstallmentPlan: InstallmentPlan?
    @State private var isShowingEditInstallmentSheet = false
    @State private var editInstallmentName: String = ""
    @State private var editInstallmentMonthlyPayment: Decimal?
    @State private var editInstallmentMonthlyInterest: Decimal?
    @State private var editInstallmentAnnualInterestRate: Decimal?
    @State private var editInstallmentInitialPrincipal: Decimal?
    @State private var editInstallmentStartDate: Date = Date()
    @State private var editInstallmentHasEndDate: Bool = false
    @State private var editInstallmentEndDate: Date = Date()
    @State private var editInstallmentPaymentDay: Int = 1
    @State private var planningWeeks: Int = 12
    @State private var selectedWeekStart: Date?
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

    var body: some View {
        Form {
            Section("Bereich") {
                if mode == .expenses {
                    Picker("Bereich", selection: $selectedTab) {
                        ForEach(StatsTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Picker("Bereich", selection: $selectedReportsTab) {
                        ForEach(ReportsTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            if !(mode == .expenses && selectedTab == .fixedCosts) {
                Section("Monat") {
                    Picker("Monat", selection: $selectedMonth) {
                        ForEach(availableMonths, id: \.self) { month in
                            Text(monthLabel(for: month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)

                    if mode == .expenses {
                        Picker("Datenbasis", selection: $dataScope) {
                            ForEach(DataScope.allCases) { scope in
                                Text(scope.rawValue).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else if selectedReportsTab == .invoices {
                        Picker("Status", selection: $reportInvoiceStatusScope) {
                            ForEach(ReportInvoiceStatusScope.allCases) { scope in
                                Text(scope.rawValue).tag(scope)
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
                                ("Anzahl Rechnungen", "\(monthlyOpenInvoiceCount)", true),
                                ("Betrag Rechnungen", monthlyOpenInvoiceAmount.formatted(.currency(code: "EUR")), true),
                                ("Fixkosten offen", monthlyOpenFixedCostAmount.formatted(.currency(code: "EUR")), false),
                                ("Gesamt offen", monthlyTotalOpenAmount.formatted(.currency(code: "EUR")), true),
                            ])
                        } else {
                            metricsCard(rows: [
                                ("Anzahl Rechnungen", "\(monthlyInvoiceCountAll)", true),
                                ("Betrag Rechnungen", monthlyInvoiceAmountAll.formatted(.currency(code: "EUR")), true),
                                ("Davon offen", "\(monthlyOpenInvoiceCount) · \(monthlyOpenInvoiceAmount.formatted(.currency(code: "EUR")))", false),
                                ("Davon bezahlt", "\(monthlyPaidInvoiceCount) · \(monthlyPaidInvoiceAmount.formatted(.currency(code: "EUR")))", false),
                                ("Fixkosten offen", "\(monthlyOpenFixedCostCount) · \(monthlyOpenFixedCostAmount.formatted(.currency(code: "EUR")))", false),
                                ("Fixkosten bezahlt", "\(monthlyPaidFixedCostCount) · \(monthlyPaidFixedCostAmount.formatted(.currency(code: "EUR")))", false),
                                ("Gesamt offen", monthlyTotalOpenAmount.formatted(.currency(code: "EUR")), false),
                                ("Gesamt bezahlt", monthlyTotalPaidAmount.formatted(.currency(code: "EUR")), false),
                                ("Gesamt", monthlyTotalAmount.formatted(.currency(code: "EUR")), true),
                            ])
                        }
                    } else {
                        metricsCard(rows: [
                            ("Einnahmen", reportActualIncome.formatted(.currency(code: "EUR")), true),
                            ("Ausgaben", reportActualExpenses.formatted(.currency(code: "EUR")), true),
                            ("Differenz", reportActualDifference.formatted(.currency(code: "EUR")), true),
                            ("Noch fällig Einnahmen", reportPendingIncome.formatted(.currency(code: "EUR")), false),
                            ("Noch fällig Ausgaben", reportPendingExpenses.formatted(.currency(code: "EUR")), false),
                            ("Noch fällige Differenz", reportPendingDifference.formatted(.currency(code: "EUR")), false),
                            ("Differenz Monatsende", reportPlannedMonthEndDifference.formatted(.currency(code: "EUR")), true),
                        ])
                    }
                } header: {
                    HStack {
                        Text("Übersicht")
                        Spacer()
                        if mode == .reports {
                            Text("Stand \(reportAsOfDateText)")
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
        .navigationTitle(mode == .expenses ? "Ausgaben" : "Auswertung")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .tint(Color(red: 0.54, green: 0.35, blue: 0.25))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Zurück") {
                    dismiss()
                }
            }
            if mode == .reports {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export erstellen") {
                        if refreshExportFile() {
                            exportStatusMessage = "Export erstellt. Jetzt auf 'Teilen' tippen."
                        } else {
                            exportStatusMessage = "Export fehlgeschlagen. Bitte Format auf CSV stellen und erneut versuchen."
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Text("Teilen")
                        }
                    }
                }
            }
        }
        .onAppear {
            if let first = availableMonths.first {
                selectedMonth = first
            } else {
                selectedMonth = startOfMonth(for: Date())
            }
        }
        .task(id: weeklyPlanRowsSignature) {
            await updateNegativeCashflowAlertIfNeeded()
        }
        .overlay(alignment: .bottom) {
            if let exportStatusMessage {
                Text(exportStatusMessage)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 10)
            }
        }
        .sheet(isPresented: $isShowingEditInstallmentSheet) {
            NavigationStack {
                Form {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bezeichnung")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("z. B. Auto Leasing", text: $editInstallmentName)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Monatliche Rate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("z. B. 420,00", value: $editInstallmentMonthlyPayment, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sollzins p.a. (%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("optional, z. B. 5,49", value: $editInstallmentAnnualInterestRate, format: .number.precision(.fractionLength(3)))
                            .keyboardType(.decimalPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Zinsanteil pro Monat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("optional, falls kein Sollzins", value: $editInstallmentMonthlyInterest, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Anfangsschuld")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("optional, z. B. 18000,00", value: $editInstallmentInitialPrincipal, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Startdatum", selection: $editInstallmentStartDate, displayedComponents: .date)
                    Stepper("Fälligkeitstag: \(editInstallmentPaymentDay).", value: $editInstallmentPaymentDay, in: 1...28)
                    Toggle("Enddatum setzen", isOn: $editInstallmentHasEndDate)
                    if editInstallmentHasEndDate {
                        DatePicker("Enddatum", selection: $editInstallmentEndDate, displayedComponents: .date)
                    }
                }
                .navigationTitle("Kredit bearbeiten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            isShowingEditInstallmentSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            saveEditedInstallmentPlan()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var reportsPlanningSections: some View {
        if mode == .reports {
            Section("Liquiditätsplanung (\(planningWeeks) Wochen)") {
                Picker("Zeitraum", selection: $planningWeeks) {
                    Text("6").tag(6)
                    Text("12").tag(12)
                    Text("24").tag(24)
                }
                .pickerStyle(.segmented)

                Toggle("Aktuellen Kontostand verwenden", isOn: $useCurrentBalance)
                if useCurrentBalance {
                    TextField("Aktueller Kontostand", value: $currentBalance, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                } else {
                    TextField("Startbestand", value: $startBalance, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }

                if !effectiveUseCurrentBalance && overdueOpenAmount > 0 {
                    LabeledContent("Überfällig/sofort", value: overdueOpenAmount.formatted(.currency(code: "EUR")))
                        .foregroundStyle(.red)
                }

                ForEach(weeklyPlanRows) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(row.label)
                                .font(.subheadline)
                            Spacer()
                            Text(row.totalOutgoing.formatted(.currency(code: "EUR")))
                                .fontWeight(.medium)
                                .monospacedDigit()
                        }
                        HStack {
                            Text("Rechnung \(row.invoiceOutgoing.formatted(.currency(code: "EUR"))) · Raten \(row.installmentOutgoing.formatted(.currency(code: "EUR")))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        HStack {
                            Text("Prognose")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(row.projectedBalance.formatted(.currency(code: "EUR")))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(row.projectedBalance < 0 ? .red : .secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedWeekStart = row.weekStart
                    }
                }
            }

            Section("Chart (\(planningWeeks) Wochen)") {
                Chart {
                    ForEach(weeklyPlanRows) { row in
                        BarMark(
                            x: .value("Woche", row.weekStart),
                            y: .value("Ausgaben", row.totalOutgoing)
                        )
                        .foregroundStyle(by: .value("Typ", "Ausgaben"))

                        BarMark(
                            x: .value("Woche", row.weekStart),
                            y: .value("Einnahmen", row.income)
                        )
                        .foregroundStyle(by: .value("Typ", "Einnahmen"))

                        LineMark(
                            x: .value("Woche", row.weekStart),
                            y: .value("Kontostand", row.projectedBalance)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("Typ", "Kontostand"))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        PointMark(
                            x: .value("Woche", row.weekStart),
                            y: .value("Kontostand", row.projectedBalance)
                        )
                        .foregroundStyle(by: .value("Typ", "Kontostand"))
                    }

                    RuleMark(y: .value("Null", 0))
                        .foregroundStyle(.gray.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartForegroundStyleScale([
                    "Ausgaben": .red.opacity(0.45),
                    "Einnahmen": .green.opacity(0.45),
                    "Kontostand": Color(red: 0.54, green: 0.35, blue: 0.25)
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

            Section("Wochen-Details") {
                ForEach(weeklyDetailRows) { row in
                    DisclosureGroup {
                        if row.totalOutgoing <= 0 {
                            Text("Keine Ausgaben in dieser Woche.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nach Empfänger")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(row.recipientBreakdown) { item in
                                    HStack {
                                        Text(item.name)
                                        Spacer()
                                        Text(item.amount.formatted(.currency(code: "EUR")))
                                            .fontWeight(.medium)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ratenzahlungen")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(row.installmentOutgoing.formatted(.currency(code: "EUR")))
                                    .fontWeight(.medium)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nach Kategorie")
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
                                Text("Ausgewählt")
                                    .font(.caption2)
                                    .foregroundStyle(Color(red: 0.54, green: 0.35, blue: 0.25))
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
            Section("Nach Kategorie") {
                if categoryRows.isEmpty {
                    ContentUnavailableView("Keine Daten", systemImage: "chart.pie")
                } else {
                    ForEach(categoryRows) { row in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.name)
                                    .font(.headline.weight(.semibold))
                                Text("\(row.count) Rechnung(en)")
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

            Section("Nach Anbieter") {
                if vendorRows.isEmpty {
                    ContentUnavailableView("Keine Daten", systemImage: "building.2")
                } else {
                    ForEach(vendorRows) { row in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.vendor)
                                    .font(.headline.weight(.semibold))
                                Text("\(row.count) Rechnung(en)")
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

            Section("Nach Zahlungsempfänger") {
                if recipientRows.isEmpty {
                    ContentUnavailableView("Keine Daten", systemImage: "chart.bar")
                } else {
                    ForEach(recipientRows) { row in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.recipient)
                                    .font(.headline.weight(.semibold))
                                Text("\(row.count) Rechnung(en)")
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
            Section("Fixkosten-Bereich") {
                Picker("Ansicht", selection: $selectedFixedCostsTab) {
                    ForEach(FixedCostsTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
            }

            if selectedFixedCostsTab == .installments {
                Section("Ratenzahlungen") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bezeichnung")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("z. B. Auto Leasing", text: $installmentName)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Monatliche Rate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("z. B. 420,00", value: $installmentMonthlyPayment, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sollzins p.a. (%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("optional, z. B. 5,49", value: $installmentAnnualInterestRate, format: .number.precision(.fractionLength(3)))
                            .keyboardType(.decimalPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Zinsanteil pro Monat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("optional, falls kein Sollzins", value: $installmentMonthlyInterest, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Anfangsschuld")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("optional, z. B. 18000,00", value: $installmentInitialPrincipal, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Startdatum", selection: $installmentStartDate, displayedComponents: .date)
                    Stepper("Fälligkeitstag: \(installmentPaymentDay).", value: $installmentPaymentDay, in: 1...28)
                    Toggle("Enddatum setzen", isOn: $installmentHasEndDate)
                    if installmentHasEndDate {
                        DatePicker("Enddatum", selection: $installmentEndDate, displayedComponents: .date)
                    }
                    Button("Rate speichern") {
                        addInstallmentPlan()
                    }
                    .buttonStyle(.borderedProminent)

                    if sortedInstallmentPlans.isEmpty {
                        Text("Keine Ratenpläne hinterlegt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedInstallmentPlans) { plan in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.name)
                                    Text(rateSubtitle(plan))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(plan.monthlyPayment.formatted(.currency(code: "EUR")))
                                        .fontWeight(.semibold)
                                        .monospacedDigit()
                                    Text("Zins \(currentInstallmentSplit(for: plan).interest.formatted(.currency(code: "EUR"))) · Tilgung \(currentInstallmentSplit(for: plan).principal.formatted(.currency(code: "EUR")))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    if let remainingNow = remainingPrincipalAfterSpecialRepayments(of: plan, at: Date()) {
                                        Text("Restschuld heute \(remainingNow.formatted(.currency(code: "EUR")))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let remaining12m = remainingPrincipalAfterSpecialRepayments(of: plan, at: calendar.date(byAdding: .month, value: 12, to: Date()) ?? Date()) {
                                        Text("Restschuld in 12M \(remaining12m.formatted(.currency(code: "EUR")))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .swipeActions {
                                Button {
                                    beginEditingInstallmentPlan(plan)
                                } label: {
                                    Text("Bearbeiten")
                                }
                                .tint(Color(red: 0.54, green: 0.35, blue: 0.25))
                                Button(role: .destructive) {
                                    modelContext.delete(plan)
                                    try? modelContext.save()
                                    refreshExportFile()
                                } label: {
                                    Text("Löschen")
                                }
                            }
                        }
                    }
                }
            } else {
                Section("Sondertilgung erfassen") {
                    Picker("Kredit", selection: $selectedRepaymentPlanID) {
                        Text("Bitte wählen").tag(Optional<UUID>.none)
                        ForEach(sortedInstallmentPlans) { plan in
                            Text(plan.name).tag(Optional(plan.id))
                        }
                    }
                    .pickerStyle(.menu)

                    DatePicker("Datum", selection: $specialRepaymentDate, displayedComponents: .date)
                    TextField("Sondertilgung in EUR", value: $specialRepaymentAmount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)

                    Button("Sondertilgung geleistet") {
                        addSpecialRepayment()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("Restschuld (Stand heute)") {
                    if sortedInstallmentPlans.isEmpty {
                        Text("Keine Kredite/Fixkosten hinterlegt.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedInstallmentPlans) { plan in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.name)
                                        .font(.headline.weight(.semibold))
                                    Text("Sondertilgung gesamt: \(specialRepaymentTotal(for: plan, upTo: Date()).formatted(.currency(code: "EUR")))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text((remainingPrincipalAfterSpecialRepayments(of: plan, at: Date()) ?? 0).formatted(.currency(code: "EUR")))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
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
                    amount: plan.monthlyPayment,
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

    private var recipientRows: [RecipientRow] {
        var grouped: [String: RecipientRow] = [:]
        for invoice in reportInvoicesForSelectedMonth {
            let vendorDisplay = cleanedDisplayName(from: invoice.vendorName, fallback: "Unbekannt")
            let recipientDisplay = cleanedDisplayName(from: invoice.paymentRecipient, fallback: vendorDisplay)
            let normalizedVendor = normalizedPartyKey(vendorDisplay)
            let normalizedRecipient = normalizedPartyKey(recipientDisplay)
            // Avoid duplicate counting in recipient section when recipient is identical to vendor.
            guard normalizedRecipient != normalizedVendor else { continue }

            let current = grouped[normalizedRecipient] ?? RecipientRow(recipient: recipientDisplay, total: 0, count: 0)
            grouped[normalizedRecipient] = RecipientRow(
                recipient: current.recipient,
                total: current.total + (invoice.amount ?? 0),
                count: current.count + 1
            )
        }

        return Array(grouped.values).sorted { $0.total > $1.total }
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
            let recipientBreakdown = buildRecipientBreakdown(weekInvoices)
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
                    recipientBreakdown: recipientBreakdown,
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

    private func buildRecipientBreakdown(_ invoices: [Invoice]) -> [BreakdownItem] {
        var grouped: [String: Double] = [:]
        for invoice in invoices {
            let recipient = invoice.paymentRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? invoice.vendorName : invoice.paymentRecipient
            grouped[recipient, default: 0] += amountValue(for: invoice)
        }
        return grouped
            .map { BreakdownItem(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
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
            total += NSDecimalNumber(decimal: plan.monthlyPayment).doubleValue
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
                ["Monat", monthLabel(for: selectedMonth)],
                ["Datenbasis", dataScope.rawValue],
                ["Liquiditäts-Basis", effectiveUseCurrentBalance ? "Aktueller Kontostand" : "Startbestand"],
                ["Basiswert", numberString(planningBaseBalance)]
            ]

            if mode == .reports {
                return baseRows + [
                    ["Einnahmen (\(reportAsOfLabel))", numberString(reportActualIncome)],
                    ["Ausgaben (\(reportAsOfLabel))", numberString(reportActualExpenses)],
                    ["Differenz (\(reportAsOfLabel))", numberString(reportActualDifference)],
                    ["Noch fällig Einnahmen", numberString(reportPendingIncome)],
                    ["Noch fällig Ausgaben", numberString(reportPendingExpenses)],
                    ["Noch fällige Differenz", numberString(reportPendingDifference)],
                    ["Differenz Monatsende", numberString(reportPlannedMonthEndDifference)]
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
                    invoice.paymentRecipient,
                    invoice.category,
                    decimalString(invoice.amount ?? 0),
                    invoice.invoiceNumber ?? ""
                ]
            }
        let invoiceDetailTotal = [
            "SUMME", "", "", "", "", "",
            decimalString(invoiceDetailRows.reduce(Decimal.zero) { partial, row in
                partial + (Decimal(string: row[6]) ?? 0)
            }),
            ""
        ]

        let recipientsByAmount = recipientRows
            .sorted { $0.total > $1.total }
            .map { [$0.recipient, "\($0.count)", decimalString($0.total)] }
        let recipientsByName = recipientRows
            .sorted { $0.recipient.localizedCaseInsensitiveCompare($1.recipient) == .orderedAscending }
            .map { [$0.recipient, "\($0.count)", decimalString($0.total)] }

        let categoriesByAmount = categoryRows
            .sorted { $0.amount > $1.amount }
            .map { [$0.name, "\($0.count)", decimalString($0.amount)] }
        let categoriesByName = categoryRows
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map { [$0.name, "\($0.count)", decimalString($0.amount)] }

        let recipientSumRow = [
            "SUMME",
            "\(recipientRows.reduce(0) { $0 + $1.count })",
            decimalString(recipientRows.reduce(Decimal.zero) { $0 + $1.total })
        ]
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
        let debtRows = sortedInstallmentPlans.map { plan in
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
            "", "", "", "",
            decimalString(sortedInstallmentPlans.filter(\.isActive).reduce(Decimal.zero) { $0 + $1.monthlyPayment }),
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
            [["Bezeichnung", "Start", "Ende", "Tag", "Aktiv", "Rate", "Sollzins_pa", "Zins_aktuell", "Tilgung_aktuell"]]
            + installmentRows
            + [installmentSumRow]

        let worksheets: [(String, [[String]])] = [
            ("Monatsübersicht", [["Feld", "Wert"]] + monthMetaRows),
            ("Rechnungsdetails", [["Eingang", "Fällig", "Status", "Anbieter", "Empfänger", "Kategorie", "Betrag", "Rechnungsnr"]] + invoiceDetailRows + [invoiceDetailTotal]),
            ("Empfänger_nach_Betrag", [["Empfänger", "Anzahl", "Betrag"]] + recipientsByAmount + [recipientSumRow]),
            ("Empfänger_nach_Name", [["Empfänger", "Anzahl", "Betrag"]] + recipientsByName + [recipientSumRow]),
            ("Kategorien_nach_Betrag", [["Kategorie", "Anzahl", "Betrag"]] + categoriesByAmount + [categorySumRow]),
            ("Kategorien_nach_Name", [["Kategorie", "Anzahl", "Betrag"]] + categoriesByName + [categorySumRow]),
            ("Liquidität", [["Woche", "Rechnung", "Raten", "Ausgaben_total", "Einnahmen", "Prognose"]] + liquidityRows + [liquiditySumRow]),
            ("Chart_Daten", [["Woche_Start", "Woche_Label", "Einnahmen", "Ausgaben", "Kontostand"]] + chartRows),
            ("Ratenzahlungen", installmentsSheetRows),
            ("Sondertilgungen", [["Kredit", "Datum", "Betrag"]] + specialRepaymentRows + [specialRepaymentSumRow]),
            ("Restschuld", [["Bezeichnung", "Anfangsschuld", "Restschuld_heute", "Restschuld_12M", "Tilgung_monat"]] + debtRows),
            ("Einnahmen", [["Bezeichnung", "Typ", "Start", "Aktiv", "Betrag"]] + incomesRows + [incomesSumAll, incomesSumActive])
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
          <dc:creator>BillRemind</dc:creator>
          <cp:lastModifiedBy>BillRemind</cp:lastModifiedBy>
          <dcterms:created xsi:type="dcterms:W3CDTF">\(createdAt)</dcterms:created>
          <dcterms:modified xsi:type="dcterms:W3CDTF">\(createdAt)</dcterms:modified>
        </cp:coreProperties>
        """

        let appXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
          <Application>BillRemind</Application>
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

    private func addInstallmentPlan() {
        let trimmed = installmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let payment = installmentMonthlyPayment, payment > 0 else { return }
        let interest = installmentMonthlyInterest ?? Decimal.zero
        let endDate = installmentHasEndDate ? installmentEndDate : nil

        let plan = InstallmentPlan(
            name: trimmed,
            monthlyPayment: payment,
            monthlyInterest: max(Decimal.zero, interest),
            annualInterestRatePercent: installmentAnnualInterestRate,
            initialPrincipal: installmentInitialPrincipal,
            startDate: installmentStartDate,
            endDate: endDate,
            paymentDay: installmentPaymentDay,
            isActive: true
        )
        modelContext.insert(plan)
        try? modelContext.save()

        installmentName = ""
        installmentMonthlyPayment = nil
        installmentMonthlyInterest = nil
        installmentAnnualInterestRate = nil
        installmentInitialPrincipal = nil
        installmentStartDate = Date()
        installmentHasEndDate = false
        installmentEndDate = Date()
        installmentPaymentDay = 1
        refreshExportFile()
    }

    private func beginEditingInstallmentPlan(_ plan: InstallmentPlan) {
        editingInstallmentPlan = plan
        editInstallmentName = plan.name
        editInstallmentMonthlyPayment = plan.monthlyPayment
        editInstallmentMonthlyInterest = plan.monthlyInterest
        editInstallmentAnnualInterestRate = plan.annualInterestRatePercent
        editInstallmentInitialPrincipal = plan.initialPrincipal
        editInstallmentStartDate = plan.startDate
        if let endDate = plan.endDate {
            editInstallmentHasEndDate = true
            editInstallmentEndDate = endDate
        } else {
            editInstallmentHasEndDate = false
            editInstallmentEndDate = Date()
        }
        editInstallmentPaymentDay = plan.paymentDay
        isShowingEditInstallmentSheet = true
    }

    private func saveEditedInstallmentPlan() {
        guard let plan = editingInstallmentPlan else { return }
        let trimmed = editInstallmentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let payment = editInstallmentMonthlyPayment,
              payment > 0
        else { return }

        plan.name = trimmed
        plan.monthlyPayment = payment
        plan.monthlyInterest = max(0, editInstallmentMonthlyInterest ?? 0)
        plan.annualInterestRatePercent = editInstallmentAnnualInterestRate
        plan.initialPrincipal = editInstallmentInitialPrincipal
        plan.startDate = editInstallmentStartDate
        plan.endDate = editInstallmentHasEndDate ? editInstallmentEndDate : nil
        plan.paymentDay = min(max(editInstallmentPaymentDay, 1), 28)

        try? modelContext.save()
        refreshExportFile()
        isShowingEditInstallmentSheet = false
    }

    private func rateSubtitle(_ plan: InstallmentPlan) -> String {
        let start = dateString(plan.startDate)
        let end = plan.endDate.map(dateString) ?? "offen"
        let rateText = plan.annualInterestRatePercent.map { "Sollzins \($0.formatted(.number.precision(.fractionLength(2))))% p.a." } ?? "ohne Sollzins"
        return "ab \(start), Ende \(end), am \(plan.paymentDay). · \(rateText)"
    }

    private func remainingPrincipal(of plan: InstallmentPlan, at referenceDate: Date) -> Decimal? {
        guard let initial = plan.initialPrincipal else { return nil }
        var remaining = NSDecimalNumber(decimal: initial).doubleValue
        for dueDate in installmentDueDates(for: plan, upTo: referenceDate) {
            let split = installmentSplit(plan: plan, remainingBefore: remaining)
            remaining = max(0, remaining - split.principal)
            if remaining <= 0 { break }
            if let endDate = plan.endDate, dueDate > calendar.startOfDay(for: endDate) { break }
        }
        return Decimal(remaining)
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

    private func installmentSplit(plan: InstallmentPlan, remainingBefore: Double?) -> (interest: Double, principal: Double) {
        let payment = NSDecimalNumber(decimal: plan.monthlyPayment).doubleValue
        let manualInterest = NSDecimalNumber(decimal: plan.monthlyInterest).doubleValue
        let computedInterest: Double = {
            if let rate = plan.annualInterestRatePercentValue, let remainingBefore {
                return max(0, remainingBefore * rate / 100.0 / 12.0)
            }
            return max(0, manualInterest)
        }()
        let cappedInterest = min(payment, computedInterest)
        let principal = max(0, payment - cappedInterest)
        return (cappedInterest, principal)
    }

    private func currentInstallmentSplit(for plan: InstallmentPlan) -> (interest: Decimal, principal: Decimal) {
        let remaining = remainingPrincipal(of: plan, at: Date()).map { NSDecimalNumber(decimal: $0).doubleValue }
        let split = installmentSplit(plan: plan, remainingBefore: remaining)
        return (Decimal(split.interest), Decimal(split.principal))
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

    private func addSpecialRepayment() {
        guard let planID = selectedRepaymentPlanID,
              let amount = specialRepaymentAmount,
              amount > 0
        else { return }

        let repayment = InstallmentSpecialRepayment(
            planID: planID,
            amount: amount,
            repaymentDate: specialRepaymentDate
        )
        modelContext.insert(repayment)
        try? modelContext.save()

        specialRepaymentAmount = nil
        specialRepaymentDate = Date()
        refreshExportFile()
    }
}

private struct IncomeManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var incomeEntries: [IncomeEntry]

    @State private var incomeName: String = ""
    @State private var incomeAmount: Decimal?
    @State private var incomeKind: IncomeEntry.Kind = .monthlyFixed
    @State private var incomeStartDate: Date = Date()
    @State private var editingIncomeEntry: IncomeEntry?
    @State private var editIncomeName: String = ""
    @State private var editIncomeKind: IncomeEntry.Kind = .monthlyFixed
    @State private var editIncomeAmount: Decimal?
    @State private var editIncomeStartDate: Date = Date()
    @State private var isShowingEditIncomeSheet = false

    var body: some View {
        Form {
            Section("Neue Einnahme") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bezeichnung")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("z. B. Gehalt", text: $incomeName)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Betrag")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("z. B. 2800,00", value: $incomeAmount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                }
                Picker("Typ", selection: $incomeKind) {
                    ForEach(IncomeEntry.Kind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                DatePicker(incomeKind == .monthlyFixed ? "Ab (Monatstag wird übernommen)" : "Datum", selection: $incomeStartDate, displayedComponents: .date)
                Button("Einnahme speichern") {
                    addIncomeEntry()
                }
                .buttonStyle(.borderedProminent)
            }

            Section("Einnahmen (Fix + Variabel)") {
                if sortedIncomeEntries.isEmpty {
                    Text("Keine Einnahmen hinterlegt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedIncomeEntries) { income in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(income.name)
                                    .font(.headline.weight(.semibold))
                                Text("\(income.kind.title) · ab \(income.startDate.formatted(.dateTime.day().month().year()))")
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
                                Text("Bearbeiten")
                            }
                            .tint(Color(red: 0.54, green: 0.35, blue: 0.25))
                            Button(role: .destructive) {
                                modelContext.delete(income)
                                try? modelContext.save()
                            } label: {
                                Text("Löschen")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Einnahmen")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .tint(Color(red: 0.54, green: 0.35, blue: 0.25))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Zurück") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isShowingEditIncomeSheet) {
            NavigationStack {
                Form {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bezeichnung")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("z. B. Gehalt", text: $editIncomeName)
                    }
                    Picker("Typ", selection: $editIncomeKind) {
                        ForEach(IncomeEntry.Kind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Betrag")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("z. B. 2800,00", value: $editIncomeAmount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                    }
                    DatePicker(editIncomeDateLabel, selection: $editIncomeStartDate, displayedComponents: .date)
                }
                .navigationTitle("Einnahme bearbeiten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            isShowingEditIncomeSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Speichern") {
                            saveEditedIncome()
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
            existing.startDate = incomeStartDate
            existing.isActive = true
        } else {
            let entry = IncomeEntry(
                name: trimmed,
                amount: amount,
                kind: incomeKind,
                startDate: incomeStartDate,
                isActive: true
            )
            modelContext.insert(entry)
        }

        try? modelContext.save()
        incomeName = ""
        incomeAmount = nil
        incomeKind = .monthlyFixed
        incomeStartDate = Date()
    }

    private var editIncomeDateLabel: String {
        if editIncomeKind == .monthlyFixed {
            return "Ab (Monatstag wird übernommen)"
        }
        return "Datum"
    }

    private func beginEditingIncome(_ income: IncomeEntry) {
        editingIncomeEntry = income
        editIncomeName = income.name
        editIncomeKind = income.kind
        editIncomeAmount = income.amount
        editIncomeStartDate = income.startDate
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
        income.startDate = editIncomeStartDate
        try? modelContext.save()
        isShowingEditIncomeSheet = false
    }
}

private struct RecipientRow: Identifiable {
    let recipient: String
    let total: Decimal
    let count: Int

    var id: String { recipient }
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
    let recipientBreakdown: [BreakdownItem]
    let categoryBreakdown: [BreakdownItem]
}

private struct BreakdownItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}

private struct CategoryRow: Identifiable {
    let name: String
    let amount: Decimal
    let count: Int

    var id: String { name }
}
