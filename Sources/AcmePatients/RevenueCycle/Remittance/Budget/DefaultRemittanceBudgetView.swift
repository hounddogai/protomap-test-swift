import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default remittance budget.
    final class DefaultRemittanceBudgetView {
        var code: String
        var title: String
        var archived: String
        var sequence: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, archived: String, sequence: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.archived = archived
            self.sequence = sequence
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRemittanceBudgetView(_ item: DefaultRemittanceBudget) -> DefaultRemittanceBudgetView {
        return DefaultRemittanceBudgetView(
            code: item.code,
            title: item.title,
            archived: "\(item.archived)",
            sequence: String(item.sequence),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRemittanceBudgetViews(_ items: [DefaultRemittanceBudget]) -> [DefaultRemittanceBudgetView] {
        var views: [DefaultRemittanceBudgetView] = []
        for item in items {
            views.append(toDefaultRemittanceBudgetView(item))
        }
        return views
    }

    static func sumDefaultRemittanceBudgetView(_ view: DefaultRemittanceBudgetView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedSequence) + Double(parsedCreatedAt)
    }
}
