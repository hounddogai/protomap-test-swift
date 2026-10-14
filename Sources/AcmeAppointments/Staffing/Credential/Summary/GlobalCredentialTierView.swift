import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global credential tier.
    final class GlobalCredentialTierView {
        var code: String
        var label: String
        var costText: String
        var discount: String
        var patientRefText: String
        var activeText: String
        var statusLabel: String

        init(code: String, label: String, costText: String, discount: String, patientRefText: String, activeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.costText = costText
            self.discount = discount
            self.patientRefText = patientRefText
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCredentialTierView(_ item: GlobalCredentialTier) -> GlobalCredentialTierView {
        return GlobalCredentialTierView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            costText: String(format: "%.2f", item.cost),
            discount: String(format: "%.2f", item.discount),
            patientRefText: item.patientRef,
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCredentialTierViews(_ items: [GlobalCredentialTier]) -> [GlobalCredentialTierView] {
        var views: [GlobalCredentialTierView] = []
        for item in items {
            views.append(toGlobalCredentialTierView(item))
        }
        return views
    }

    static func sumGlobalCredentialTierView(_ view: GlobalCredentialTierView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCost + parsedDiscount
    }
}
