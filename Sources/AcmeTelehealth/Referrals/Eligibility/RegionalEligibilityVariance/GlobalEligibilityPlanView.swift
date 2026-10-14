import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global eligibility plan.
    final class GlobalEligibilityPlanView {
        var code: String
        var label: String
        var bedText: String
        var ceilingText: String
        var country: String
        var statusLabel: String

        init(code: String, label: String, bedText: String, ceilingText: String, country: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bedText = bedText
            self.ceilingText = ceilingText
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalEligibilityPlanView(_ item: GlobalEligibilityPlan) -> GlobalEligibilityPlanView {
        return GlobalEligibilityPlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 80),
            bedText: item.bed,
            ceilingText: String(format: "%.2f", item.ceiling),
            country: Kit.Text.truncate(item.country, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalEligibilityPlanViews(_ items: [GlobalEligibilityPlan]) -> [GlobalEligibilityPlanView] {
        var views: [GlobalEligibilityPlanView] = []
        for item in items {
            views.append(toGlobalEligibilityPlanView(item))
        }
        return views
    }

    static func sumGlobalEligibilityPlanView(_ view: GlobalEligibilityPlanView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
