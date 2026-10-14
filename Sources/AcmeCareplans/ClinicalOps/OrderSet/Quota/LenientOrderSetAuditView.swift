import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient order set audit.
    final class LenientOrderSetAuditView {
        var codeText: String
        var name: String
        var budget: String
        var diagnosisCode: String
        var amountText: String
        var refills: String
        var clinicianID: String
        var revision: String
        var contactEmailText: String
        var statusLabel: String

        init(codeText: String, name: String, budget: String, diagnosisCode: String, amountText: String, refills: String, clinicianID: String, revision: String, contactEmailText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.budget = budget
            self.diagnosisCode = diagnosisCode
            self.amountText = amountText
            self.refills = refills
            self.clinicianID = clinicianID
            self.revision = revision
            self.contactEmailText = contactEmailText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientOrderSetAuditView(_ item: LenientOrderSetAudit) -> LenientOrderSetAuditView {
        return LenientOrderSetAuditView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            budget: String(format: "%.2f", item.budget),
            diagnosisCode: item.diagnosisCode,
            amountText: String(format: "%.2f", item.amount),
            refills: String(item.refills),
            clinicianID: item.clinicianID,
            revision: String(item.revision),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientOrderSetAuditViews(_ items: [LenientOrderSetAudit]) -> [LenientOrderSetAuditView] {
        var views: [LenientOrderSetAuditView] = []
        for item in items {
            views.append(toLenientOrderSetAuditView(item))
        }
        return views
    }

    static func sumLenientOrderSetAuditView(_ view: LenientOrderSetAuditView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedBudget + parsedAmount + Double(parsedRefills)
    }
}
