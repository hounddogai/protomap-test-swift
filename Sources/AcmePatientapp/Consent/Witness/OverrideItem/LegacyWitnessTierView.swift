import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy witness tier.
    final class LegacyWitnessTierView {
        var code: String
        var titleText: String
        var label: String
        var pinned: String
        var archived: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, label: String, pinned: String, archived: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.label = label
            self.pinned = pinned
            self.archived = archived
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyWitnessTierView(_ item: LegacyWitnessTier) -> LegacyWitnessTierView {
        return LegacyWitnessTierView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            label: item.label,
            pinned: "\(item.pinned)",
            archived: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyWitnessTierViews(_ items: [LegacyWitnessTier]) -> [LegacyWitnessTierView] {
        var views: [LegacyWitnessTierView] = []
        for item in items {
            views.append(toLegacyWitnessTierView(item))
        }
        return views
    }

    static func sumLegacyWitnessTierView(_ view: LegacyWitnessTierView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
