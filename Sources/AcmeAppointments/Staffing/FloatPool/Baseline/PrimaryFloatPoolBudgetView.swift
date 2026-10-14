import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary float pool budget.
    final class PrimaryFloatPoolBudgetView {
        var code: String
        var name: String
        var graceDays: String
        var priority: String
        var channel: String
        var score: String
        var statusLabel: String

        init(code: String, name: String, graceDays: String, priority: String, channel: String, score: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.priority = priority
            self.channel = channel
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryFloatPoolBudgetView(_ item: PrimaryFloatPoolBudget) -> PrimaryFloatPoolBudgetView {
        return PrimaryFloatPoolBudgetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            graceDays: String(item.graceDays),
            priority: String(item.priority),
            channel: item.channel,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryFloatPoolBudgetViews(_ items: [PrimaryFloatPoolBudget]) -> [PrimaryFloatPoolBudgetView] {
        var views: [PrimaryFloatPoolBudgetView] = []
        for item in items {
            views.append(toPrimaryFloatPoolBudgetView(item))
        }
        return views
    }

    static func sumPrimaryFloatPoolBudgetView(_ view: PrimaryFloatPoolBudgetView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedPriority) + parsedScore
    }
}
