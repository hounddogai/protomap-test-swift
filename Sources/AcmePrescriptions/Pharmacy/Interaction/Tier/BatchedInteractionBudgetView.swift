import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched interaction budget.
    final class BatchedInteractionBudgetView {
        var code: String
        var titleText: String
        var revision: String
        var archived: String
        var source: String
        var statusLabel: String

        init(code: String, titleText: String, revision: String, archived: String, source: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.revision = revision
            self.archived = archived
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedInteractionBudgetView(_ item: BatchedInteractionBudget) -> BatchedInteractionBudgetView {
        return BatchedInteractionBudgetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            revision: String(item.revision),
            archived: "\(item.archived)",
            source: Kit.Text.truncate(item.source, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedInteractionBudgetViews(_ items: [BatchedInteractionBudget]) -> [BatchedInteractionBudgetView] {
        var views: [BatchedInteractionBudgetView] = []
        for item in items {
            views.append(toBatchedInteractionBudgetView(item))
        }
        return views
    }

    static func sumBatchedInteractionBudgetView(_ view: BatchedInteractionBudgetView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedRevision)
    }
}
