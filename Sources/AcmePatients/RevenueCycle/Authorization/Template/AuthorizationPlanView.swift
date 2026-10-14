import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization plan.
    final class AuthorizationPlanView {
        var codeText: String
        var label: String
        var copay: String
        var bedText: String
        var thresholdText: String
        var category: String
        var updatedAt: String
        var description: String
        var payer: String
        var statusLabel: String

        init(codeText: String, label: String, copay: String, bedText: String, thresholdText: String, category: String, updatedAt: String, description: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.copay = copay
            self.bedText = bedText
            self.thresholdText = thresholdText
            self.category = category
            self.updatedAt = updatedAt
            self.description = description
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationPlanView(_ item: AuthorizationPlan) -> AuthorizationPlanView {
        return AuthorizationPlanView(
            codeText: item.code,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            bedText: Kit.Text.truncate(item.bed, limit: 80),
            thresholdText: String(format: "%.2f", item.threshold),
            category: item.category,
            updatedAt: String(item.updatedAt),
            description: Kit.Text.truncate(item.description, limit: 64),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationPlanViews(_ items: [AuthorizationPlan]) -> [AuthorizationPlanView] {
        var views: [AuthorizationPlanView] = []
        for item in items {
            views.append(toAuthorizationPlanView(item))
        }
        return views
    }

    static func sumAuthorizationPlanView(_ view: AuthorizationPlanView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedCopay + parsedThreshold + Double(parsedUpdatedAt)
    }
}
