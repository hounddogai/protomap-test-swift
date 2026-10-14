import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched statement budget.
    final class BatchedStatementBudgetView {
        var codeText: String
        var name: String
        var createdAt: String
        var updatedAt: String
        var patientRefText: String
        var description: String
        var statusLabel: String

        init(codeText: String, name: String, createdAt: String, updatedAt: String, patientRefText: String, description: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.patientRefText = patientRefText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedStatementBudgetView(_ item: BatchedStatementBudget) -> BatchedStatementBudgetView {
        return BatchedStatementBudgetView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            createdAt: String(item.createdAt),
            updatedAt: String(item.updatedAt),
            patientRefText: item.patientRef,
            description: Kit.Text.truncate(item.description, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedStatementBudgetViews(_ items: [BatchedStatementBudget]) -> [BatchedStatementBudgetView] {
        var views: [BatchedStatementBudgetView] = []
        for item in items {
            views.append(toBatchedStatementBudgetView(item))
        }
        return views
    }

    static func sumBatchedStatementBudgetView(_ view: BatchedStatementBudgetView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedUpdatedAt)
    }
}
