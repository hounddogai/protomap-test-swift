import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal claim.
    final class GoalClaimView {
        var code: String
        var name: String
        var budget: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, budget: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budget = budget
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toGoalClaimView(_ item: GoalClaim) -> GoalClaimView {
        return GoalClaimView(
            code: item.code,
            name: item.name,
            budget: String(format: "%.2f", item.budget),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalClaimViews(_ items: [GoalClaim]) -> [GoalClaimView] {
        var views: [GoalClaimView] = []
        for item in items {
            views.append(toGoalClaimView(item))
        }
        return views
    }

    static func sumGoalClaimView(_ view: GoalClaimView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedBudget + Double(parsedBatchSize)
    }
}
