import SwiftUI

enum AppTheme {
    /// Primary brand accent. Matches the "Open" status badge text color in the
    /// invoice list so the in-app navy stays consistent across UI surfaces.
    static let accent = Color(red: 0.16, green: 0.33, blue: 0.50)
}

/// Hero header used at the top of main screens (Invoices, Expenses, Analytics,
/// Income). Shows a gradient icon tile next to a bold title and optional
/// subtitle so each section has a recognizable visual identity instead of the
/// plain inline navigation title. Optional trailing slot lets a screen embed
/// a primary action (e.g. the "+" button on Invoices) without growing taller.
struct AppHeroHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let bottomPadding: CGFloat
    let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        bottomPadding: CGFloat = 10,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.bottomPadding = bottomPadding
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            iconTile
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, bottomPadding)
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.accent.opacity(0.95), AppTheme.accent.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 46, height: 46)
                .shadow(color: AppTheme.accent.opacity(0.28), radius: 6, x: 0, y: 3)
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
        }
    }
}
