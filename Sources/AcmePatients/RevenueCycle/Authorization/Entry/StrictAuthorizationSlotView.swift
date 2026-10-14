import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a strict authorization slot.
    final class StrictAuthorizationSlotView {
        var code: String
        var title: String
        var quantity: String
        var payer: String
        var archived: String
        var statusLabel: String

        init(code: String, title: String, quantity: String, payer: String, archived: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.payer = payer
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toStrictAuthorizationSlotView(_ item: StrictAuthorizationSlot) -> StrictAuthorizationSlotView {
        return StrictAuthorizationSlotView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            quantity: String(item.quantity),
            payer: Kit.Text.truncate(item.payer, limit: 120),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictAuthorizationSlotViews(_ items: [StrictAuthorizationSlot]) -> [StrictAuthorizationSlotView] {
        var views: [StrictAuthorizationSlotView] = []
        for item in items {
            views.append(toStrictAuthorizationSlotView(item))
        }
        return views
    }

    static func sumStrictAuthorizationSlotView(_ view: StrictAuthorizationSlotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
