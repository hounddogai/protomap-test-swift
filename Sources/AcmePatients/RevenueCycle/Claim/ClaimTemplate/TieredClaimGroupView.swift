import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered claim group.
    final class TieredClaimGroupView {
        var code: String
        var title: String
        var notes: String
        var updatedAt: String
        var active: String
        var country: String
        var endsAtText: String
        var margin: String
        var statusLabel: String

        init(code: String, title: String, notes: String, updatedAt: String, active: String, country: String, endsAtText: String, margin: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notes = notes
            self.updatedAt = updatedAt
            self.active = active
            self.country = country
            self.endsAtText = endsAtText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toTieredClaimGroupView(_ item: TieredClaimGroup) -> TieredClaimGroupView {
        return TieredClaimGroupView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 40),
            notes: item.notes,
            updatedAt: String(item.updatedAt),
            active: "\(item.active)",
            country: Kit.Text.truncate(item.country, limit: 64),
            endsAtText: String(item.endsAt),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredClaimGroupViews(_ items: [TieredClaimGroup]) -> [TieredClaimGroupView] {
        var views: [TieredClaimGroupView] = []
        for item in items {
            views.append(toTieredClaimGroupView(item))
        }
        return views
    }

    static func sumTieredClaimGroupView(_ view: TieredClaimGroupView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedEndsAt) + parsedMargin
    }
}
