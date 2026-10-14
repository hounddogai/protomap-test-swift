import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization override.
    final class AuthorizationOverrideView {
        var codeText: String
        var title: String
        var specialty: String
        var amount: String
        var approvedText: String
        var budgetText: String
        var statusLabel: String

        init(codeText: String, title: String, specialty: String, amount: String, approvedText: String, budgetText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.specialty = specialty
            self.amount = amount
            self.approvedText = approvedText
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationOverrideView(_ item: AuthorizationOverride) -> AuthorizationOverrideView {
        return AuthorizationOverrideView(
            codeText: item.code,
            title: item.title,
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            amount: String(format: "%.2f", item.amount),
            approvedText: "\(item.approved)",
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationOverrideViews(_ items: [AuthorizationOverride]) -> [AuthorizationOverrideView] {
        var views: [AuthorizationOverrideView] = []
        for item in items {
            views.append(toAuthorizationOverrideView(item))
        }
        return views
    }

    static func sumAuthorizationOverrideView(_ view: AuthorizationOverrideView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedAmount + parsedBudget
    }
}
