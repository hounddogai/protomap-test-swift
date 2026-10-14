import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted follow up slot.
    final class WeightedFollowUpSlotView {
        var code: String
        var label: String
        var discount: String
        var marginText: String
        var copay: String
        var statusLabel: String

        init(code: String, label: String, discount: String, marginText: String, copay: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.marginText = marginText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFollowUpSlotView(_ item: WeightedFollowUpSlot) -> WeightedFollowUpSlotView {
        return WeightedFollowUpSlotView(
            code: item.code,
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            marginText: String(format: "%.2f", item.margin),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFollowUpSlotViews(_ items: [WeightedFollowUpSlot]) -> [WeightedFollowUpSlotView] {
        var views: [WeightedFollowUpSlotView] = []
        for item in items {
            views.append(toWeightedFollowUpSlotView(item))
        }
        return views
    }

    static func sumWeightedFollowUpSlotView(_ view: WeightedFollowUpSlotView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedDiscount + parsedMargin + parsedCopay
    }
}
