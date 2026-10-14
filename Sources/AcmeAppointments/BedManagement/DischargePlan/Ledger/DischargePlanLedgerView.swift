import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan ledger.
    final class DischargePlanLedgerView {
        var code: String
        var name: String
        var patientRefText: String
        var budget: String
        var rate: String
        var statusLabel: String

        init(code: String, name: String, patientRefText: String, budget: String, rate: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRefText = patientRefText
            self.budget = budget
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanLedgerView(_ item: DischargePlanLedger) -> DischargePlanLedgerView {
        return DischargePlanLedgerView(
            code: item.code,
            name: item.name,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            budget: String(format: "%.2f", item.budget),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanLedgerViews(_ items: [DischargePlanLedger]) -> [DischargePlanLedgerView] {
        var views: [DischargePlanLedgerView] = []
        for item in items {
            views.append(toDischargePlanLedgerView(item))
        }
        return views
    }

    static func sumDischargePlanLedgerView(_ view: DischargePlanLedgerView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedBudget + parsedRate
    }
}
