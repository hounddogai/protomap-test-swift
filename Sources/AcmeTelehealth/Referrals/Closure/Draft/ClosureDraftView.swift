import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure draft.
    final class ClosureDraftView {
        var code: String
        var nameText: String
        var allergy: String
        var region: String
        var quantityText: String
        var archived: String
        var currencyText: String
        var externalRefText: String
        var activeText: String
        var statusLabel: String

        init(code: String, nameText: String, allergy: String, region: String, quantityText: String, archived: String, currencyText: String, externalRefText: String, activeText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.allergy = allergy
            self.region = region
            self.quantityText = quantityText
            self.archived = archived
            self.currencyText = currencyText
            self.externalRefText = externalRefText
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureDraftView(_ item: ClosureDraft) -> ClosureDraftView {
        return ClosureDraftView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            allergy: item.allergy,
            region: item.region,
            quantityText: String(item.quantity),
            archived: "\(item.archived)",
            currencyText: item.currency,
            externalRefText: item.externalRef,
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureDraftViews(_ items: [ClosureDraft]) -> [ClosureDraftView] {
        var views: [ClosureDraftView] = []
        for item in items {
            views.append(toClosureDraftView(item))
        }
        return views
    }

    static func sumClosureDraftView(_ view: ClosureDraftView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
