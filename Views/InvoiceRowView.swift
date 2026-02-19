import SwiftUI

struct InvoiceRowView: View {
    let invoice: Invoice
    var isLikelyDuplicate: Bool = false
    @AppStorage(AppSettings.urgencySoonDaysKey) private var urgencySoonDays: Int = AppSettings.urgencySoonDays
    private let calendar = Calendar.current

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 7) {
                Text(invoice.vendorName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.15, green: 0.23, blue: 0.33))
                    .lineLimit(1)
                if let amount = invoice.amount {
                    Text(amount, format: .currency(code: "EUR"))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color(red: 0.09, green: 0.15, blue: 0.23))
                        .monospacedDigit()
                }
                if let dueDate = invoice.dueDate {
                    Text("Fällig: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(red: 0.39, green: 0.47, blue: 0.58))
                } else if invoice.status == .paid, let paidAt = invoice.paidAt {
                    Text("Bezahlt: \(paidAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(red: 0.39, green: 0.47, blue: 0.58))
                }
                if isLikelyDuplicate {
                    Text("Mögliche Dublette")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(red: 0.72, green: 0.24, blue: 0.24))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(invoice.status == .open ? "Offen" : "Bezahlt")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusBackgroundColor)
                    .foregroundStyle(statusTextColor)
                    .clipShape(Capsule())

                if let urgencyText {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(statusAccentColor)
                            .frame(width: 7, height: 7)
                        Text(urgencyText)
                            .font(.caption2)
                            .foregroundStyle(statusAccentColor)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.82, green: 0.86, blue: 0.91), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }

    private var urgencyText: String? {
        guard invoice.status == .open, let dueDate = invoice.dueDate else { return nil }
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0
        if days < 0 { return "Überfällig" }
        if days <= urgencySoonDays { return "Bald fällig" }
        return nil
    }

    private var statusBackgroundColor: Color {
        if invoice.status != .open { return Color(red: 0.84, green: 0.93, blue: 0.86) }
        if urgencyText == "Überfällig" { return Color(red: 0.97, green: 0.83, blue: 0.82) }
        if urgencyText == "Bald fällig" { return Color(red: 0.93, green: 0.89, blue: 0.79) }
        return Color(red: 0.87, green: 0.92, blue: 0.97)
    }

    private var statusTextColor: Color {
        if invoice.status != .open { return Color(red: 0.13, green: 0.37, blue: 0.20) }
        if urgencyText == "Überfällig" { return Color(red: 0.58, green: 0.20, blue: 0.20) }
        if urgencyText == "Bald fällig" { return Color(red: 0.44, green: 0.31, blue: 0.18) }
        return Color(red: 0.16, green: 0.33, blue: 0.50)
    }

    private var statusAccentColor: Color {
        if urgencyText == "Überfällig" { return .red }
        return .orange
    }
}
