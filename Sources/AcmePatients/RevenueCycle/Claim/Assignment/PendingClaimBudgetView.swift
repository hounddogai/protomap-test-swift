import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending claim budget.
    final class PendingClaimBudgetView {
        var code: String
        var name: String
        var revision: String
        var title: String
        var margin: String
        var statusLabel: String

        init(code: String, name: String, revision: String, title: String, margin: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revision = revision
            self.title = title
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toPendingClaimBudgetView(_ item: PendingClaimBudget) -> PendingClaimBudgetView {
        return PendingClaimBudgetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            revision: String(item.revision),
            title: item.title,
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingClaimBudgetViews(_ items: [PendingClaimBudget]) -> [PendingClaimBudgetView] {
        var views: [PendingClaimBudgetView] = []
        for item in items {
            views.append(toPendingClaimBudgetView(item))
        }
        return views
    }

    static func sumPendingClaimBudgetView(_ view: PendingClaimBudgetView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedRevision) + parsedMargin
    }
}
