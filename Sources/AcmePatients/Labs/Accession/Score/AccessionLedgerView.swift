import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession ledger.
    final class AccessionLedgerView {
        var code: String
        var name: String
        var procedureCodeText: String
        var active: String
        var discountText: String
        var patientRef: String
        var budgetText: String
        var weight: String
        var revision: String
        var refills: String
        var rate: String
        var statusLabel: String

        init(code: String, name: String, procedureCodeText: String, active: String, discountText: String, patientRef: String, budgetText: String, weight: String, revision: String, refills: String, rate: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCodeText = procedureCodeText
            self.active = active
            self.discountText = discountText
            self.patientRef = patientRef
            self.budgetText = budgetText
            self.weight = weight
            self.revision = revision
            self.refills = refills
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionLedgerView(_ item: AccessionLedger) -> AccessionLedgerView {
        return AccessionLedgerView(
            code: item.code,
            name: item.name,
            procedureCodeText: item.procedureCode,
            active: "\(item.active)",
            discountText: String(format: "%.2f", item.discount),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 120),
            budgetText: String(format: "%.2f", item.budget),
            weight: String(format: "%.2f", item.weight),
            revision: String(item.revision),
            refills: String(item.refills),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionLedgerViews(_ items: [AccessionLedger]) -> [AccessionLedgerView] {
        var views: [AccessionLedgerView] = []
        for item in items {
            views.append(toAccessionLedgerView(item))
        }
        return views
    }

    static func sumAccessionLedgerView(_ view: AccessionLedgerView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedDiscount + parsedBudget + parsedWeight
    }
}
