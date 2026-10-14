import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered eligibility template.
    final class TieredEligibilityTemplateView {
        var code: String
        var label: String
        var floorValue: String
        var category: String
        var payerText: String
        var statusLabel: String

        init(code: String, label: String, floorValue: String, category: String, payerText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.category = category
            self.payerText = payerText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredEligibilityTemplateView(_ item: TieredEligibilityTemplate) -> TieredEligibilityTemplateView {
        return TieredEligibilityTemplateView(
            code: item.code,
            label: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            category: item.category,
            payerText: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredEligibilityTemplateViews(_ items: [TieredEligibilityTemplate]) -> [TieredEligibilityTemplateView] {
        var views: [TieredEligibilityTemplateView] = []
        for item in items {
            views.append(toTieredEligibilityTemplateView(item))
        }
        return views
    }

    static func sumTieredEligibilityTemplateView(_ view: TieredEligibilityTemplateView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
