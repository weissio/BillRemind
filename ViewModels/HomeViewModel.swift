import Foundation

enum InvoiceFilter: String, CaseIterable, Identifiable {
    case open = "Offen"
    case paid = "Bezahlt"
    case all = "Alle"

    var id: String { rawValue }
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
