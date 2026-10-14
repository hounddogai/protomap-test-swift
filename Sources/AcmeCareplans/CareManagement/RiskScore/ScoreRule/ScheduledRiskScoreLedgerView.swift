import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled risk score ledger.
    final class ScheduledRiskScoreLedgerView {
        var codeText: String
        var title: String
        var graceDays: String
        var contactEmail: String
        var cost: String
        var statusLabel: String

        init(codeText: String, title: String, graceDays: String, contactEmail: String, cost: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRiskScoreLedgerView(_ item: ScheduledRiskScoreLedger) -> ScheduledRiskScoreLedgerView {
        return ScheduledRiskScoreLedgerView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            graceDays: String(item.graceDays),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRiskScoreLedgerViews(_ items: [ScheduledRiskScoreLedger]) -> [ScheduledRiskScoreLedgerView] {
        var views: [ScheduledRiskScoreLedgerView] = []
        for item in items {
            views.append(toScheduledRiskScoreLedgerView(item))
        }
        return views
    }

    static func sumScheduledRiskScoreLedgerView(_ view: ScheduledRiskScoreLedgerView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedGraceDays) + parsedCost
    }
}
