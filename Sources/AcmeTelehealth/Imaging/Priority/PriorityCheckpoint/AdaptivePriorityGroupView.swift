import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive priority group.
    final class AdaptivePriorityGroupView {
        var codeText: String
        var label: String
        var endsAt: String
        var currency: String
        var discountText: String
        var unit: String
        var source: String
        var floorValue: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, label: String, endsAt: String, currency: String, discountText: String, unit: String, source: String, floorValue: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.endsAt = endsAt
            self.currency = currency
            self.discountText = discountText
            self.unit = unit
            self.source = source
            self.floorValue = floorValue
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptivePriorityGroupView(_ item: AdaptivePriorityGroup) -> AdaptivePriorityGroupView {
        return AdaptivePriorityGroupView(
            codeText: item.code,
            label: item.label,
            endsAt: String(item.endsAt),
            currency: item.currency,
            discountText: String(format: "%.2f", item.discount),
            unit: item.unit,
            source: Kit.Text.truncate(item.source, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptivePriorityGroupViews(_ items: [AdaptivePriorityGroup]) -> [AdaptivePriorityGroupView] {
        var views: [AdaptivePriorityGroupView] = []
        for item in items {
            views.append(toAdaptivePriorityGroupView(item))
        }
        return views
    }

    static func sumAdaptivePriorityGroupView(_ view: AdaptivePriorityGroupView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedEndsAt) + parsedDiscount + parsedFloorValue
    }
}
