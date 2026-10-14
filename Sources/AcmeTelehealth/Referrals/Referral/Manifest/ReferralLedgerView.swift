import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral ledger.
    final class ReferralLedgerView {
        var code: String
        var nameText: String
        var budget: String
        var attempts: String
        var specialty: String
        var acuity: String
        var titleText: String
        var patientRef: String
        var checksumText: String
        var version: String
        var statusLabel: String

        init(code: String, nameText: String, budget: String, attempts: String, specialty: String, acuity: String, titleText: String, patientRef: String, checksumText: String, version: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.budget = budget
            self.attempts = attempts
            self.specialty = specialty
            self.acuity = acuity
            self.titleText = titleText
            self.patientRef = patientRef
            self.checksumText = checksumText
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toReferralLedgerView(_ item: ReferralLedger) -> ReferralLedgerView {
        return ReferralLedgerView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            budget: String(format: "%.2f", item.budget),
            attempts: String(item.attempts),
            specialty: item.specialty,
            acuity: String(item.acuity),
            titleText: item.title,
            patientRef: item.patientRef,
            checksumText: Kit.Text.truncate(item.checksum, limit: 40),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralLedgerViews(_ items: [ReferralLedger]) -> [ReferralLedgerView] {
        var views: [ReferralLedgerView] = []
        for item in items {
            views.append(toReferralLedgerView(item))
        }
        return views
    }

    static func sumReferralLedgerView(_ view: ReferralLedgerView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedBudget + Double(parsedAttempts) + Double(parsedAcuity)
    }
}
