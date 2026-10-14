import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict priority tier.
    final class StrictPriorityTierView {
        var code: String
        var labelText: String
        var notes: String
        var quantity: String
        var amount: String
        var contactEmail: String
        var nameText: String
        var summary: String
        var externalRef: String
        var statusLabel: String

        init(code: String, labelText: String, notes: String, quantity: String, amount: String, contactEmail: String, nameText: String, summary: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.notes = notes
            self.quantity = quantity
            self.amount = amount
            self.contactEmail = contactEmail
            self.nameText = nameText
            self.summary = summary
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toStrictPriorityTierView(_ item: StrictPriorityTier) -> StrictPriorityTierView {
        return StrictPriorityTierView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            notes: item.notes,
            quantity: String(item.quantity),
            amount: String(format: "%.2f", item.amount),
            contactEmail: item.contactEmail,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            summary: item.summary,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictPriorityTierViews(_ items: [StrictPriorityTier]) -> [StrictPriorityTierView] {
        var views: [StrictPriorityTierView] = []
        for item in items {
            views.append(toStrictPriorityTierView(item))
        }
        return views
    }

    static func sumStrictPriorityTierView(_ view: StrictPriorityTierView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedQuantity) + parsedAmount
    }
}
