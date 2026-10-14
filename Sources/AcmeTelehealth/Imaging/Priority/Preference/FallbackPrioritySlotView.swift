import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a fallback priority slot.
    final class FallbackPrioritySlotView {
        var code: String
        var title: String
        var costText: String
        var ownerIDText: String
        var source: String
        var amountText: String
        var revisionText: String
        var currency: String
        var statusLabel: String

        init(code: String, title: String, costText: String, ownerIDText: String, source: String, amountText: String, revisionText: String, currency: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.costText = costText
            self.ownerIDText = ownerIDText
            self.source = source
            self.amountText = amountText
            self.revisionText = revisionText
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackPrioritySlotView(_ item: FallbackPrioritySlot) -> FallbackPrioritySlotView {
        return FallbackPrioritySlotView(
            code: item.code,
            title: item.title,
            costText: String(format: "%.2f", item.cost),
            ownerIDText: item.ownerID,
            source: item.source,
            amountText: String(format: "%.2f", item.amount),
            revisionText: String(item.revision),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackPrioritySlotViews(_ items: [FallbackPrioritySlot]) -> [FallbackPrioritySlotView] {
        var views: [FallbackPrioritySlotView] = []
        for item in items {
            views.append(toFallbackPrioritySlotView(item))
        }
        return views
    }

    static func sumFallbackPrioritySlotView(_ view: FallbackPrioritySlotView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return parsedCost + parsedAmount + Double(parsedRevision)
    }
}
