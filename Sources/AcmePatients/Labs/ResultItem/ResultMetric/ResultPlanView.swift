import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result plan.
    final class ResultPlanView {
        var codeText: String
        var name: String
        var graceDaysText: String
        var segment: String
        var notes: String
        var archived: String
        var amount: String
        var statusLabel: String

        init(codeText: String, name: String, graceDaysText: String, segment: String, notes: String, archived: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.graceDaysText = graceDaysText
            self.segment = segment
            self.notes = notes
            self.archived = archived
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toResultPlanView(_ item: ResultPlan) -> ResultPlanView {
        return ResultPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            graceDaysText: String(item.graceDays),
            segment: Kit.Text.truncate(item.segment, limit: 64),
            notes: Kit.Text.truncate(item.notes, limit: 40),
            archived: "\(item.archived)",
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultPlanViews(_ items: [ResultPlan]) -> [ResultPlanView] {
        var views: [ResultPlanView] = []
        for item in items {
            views.append(toResultPlanView(item))
        }
        return views
    }

    static func sumResultPlanView(_ view: ResultPlanView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedGraceDays) + parsedAmount
    }
}
