import Foundation

enum InvoiceFilter: CaseIterable, Identifiable {
    case open
    case paid
    case all

    var id: String { title }

    var title: String {
        switch self {
        case .open:
            return L10n.t("Offen", "Open")
        case .paid:
            return L10n.t("Bezahlt", "Paid")
        case .all:
            return L10n.t("Alle", "All")
        }
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var filter: InvoiceFilter = .open

    func filtered(_ invoices: [Invoice]) -> [Invoice] {
        let sorted = invoices.sorted { $0.createdAt > $1.createdAt }
        switch filter {
        case .open:
            return sorted.filter { $0.status == .open }
        case .paid:
            return sorted.filter { $0.status == .paid }
        case .all:
            return sorted
        }
    }
}
