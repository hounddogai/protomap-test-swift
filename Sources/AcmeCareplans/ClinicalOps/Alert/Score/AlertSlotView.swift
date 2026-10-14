import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert slot.
    final class AlertSlotView {
        var codeText: String
        var title: String
        var limit: String
        var payer: String
        var priority: String
        var discount: String
        var startsAtText: String
        var dosageMgText: String
        var endsAt: String
        var statusLabel: String

        init(codeText: String, title: String, limit: String, payer: String, priority: String, discount: String, startsAtText: String, dosageMgText: String, endsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.limit = limit
            self.payer = payer
            self.priority = priority
            self.discount = discount
            self.startsAtText = startsAtText
            self.dosageMgText = dosageMgText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toAlertSlotView(_ item: AlertSlot) -> AlertSlotView {
        return AlertSlotView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            limit: String(item.limit),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            priority: String(item.priority),
            discount: String(format: "%.2f", item.discount),
            startsAtText: String(item.startsAt),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertSlotViews(_ items: [AlertSlot]) -> [AlertSlotView] {
        var views: [AlertSlotView] = []
        for item in items {
            views.append(toAlertSlotView(item))
        }
        return views
    }

    static func sumAlertSlotView(_ view: AlertSlotView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedLimit) + Double(parsedPriority) + parsedDiscount
    }
}
