import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy acuity plan policy.
    final class LegacyAcuityPlanPolicyView {
        var code: String
        var labelText: String
        var maximum: String
        var quantityText: String
        var approved: String
        var locale: String
        var minimum: String
        var discount: String
        var statusLabel: String

        init(code: String, labelText: String, maximum: String, quantityText: String, approved: String, locale: String, minimum: String, discount: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.maximum = maximum
            self.quantityText = quantityText
            self.approved = approved
            self.locale = locale
            self.minimum = minimum
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAcuityPlanPolicyView(_ item: LegacyAcuityPlanPolicy) -> LegacyAcuityPlanPolicyView {
        return LegacyAcuityPlanPolicyView(
            code: item.code,
            labelText: item.label,
            maximum: String(format: "%.2f", item.maximum),
            quantityText: String(item.quantity),
            approved: "\(item.approved)",
            locale: Kit.Text.truncate(item.locale, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAcuityPlanPolicyViews(_ items: [LegacyAcuityPlanPolicy]) -> [LegacyAcuityPlanPolicyView] {
        var views: [LegacyAcuityPlanPolicyView] = []
        for item in items {
            views.append(toLegacyAcuityPlanPolicyView(item))
        }
        return views
    }

    static func sumLegacyAcuityPlanPolicyView(_ view: LegacyAcuityPlanPolicyView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMaximum + Double(parsedQuantity) + parsedMinimum
    }
}
