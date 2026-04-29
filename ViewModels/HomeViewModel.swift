import Foundation

enum InvoiceFilter: String, CaseIterable, Identifiable {
    case open
    case paid
    case all

    var id: String { rawValue }

    /// Sprache wird explizit als Parameter durchgereicht, damit SwiftUI die
    /// Abhaengigkeit auf appLanguageCode erkennt und das Picker-Label bei
    /// Sprachumstellung neu rendert. Frueher wurde L10n.t direkt aus der
    /// computed property aufgerufen — das liest UserDefaults manuell und
    /// wird vom @AppStorage-Tracking nicht erkannt, sodass die Labels nach
    /// einem Sprach-Switch deutsch blieben, bis die View komplett neu
    /// aufgebaut wurde.
    func localizedTitle(isEnglish: Bool) -> String {
        switch self {
        case .open: return isEnglish ? "Open" : "Offen"
        case .paid: return isEnglish ? "Paid" : "Bezahlt"
        case .all:  return isEnglish ? "All"  : "Alle"
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
