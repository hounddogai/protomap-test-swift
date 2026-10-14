import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility ledger.
    final class EligibilityLedgerView {
        var codeText: String
        var label: String
        var active: String
        var bed: String
        var score: String
        var checksumText: String
        var pinned: String
        var contactEmail: String
        var endsAt: String
        var updatedAt: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, label: String, active: String, bed: String, score: String, checksumText: String, pinned: String, contactEmail: String, endsAt: String, updatedAt: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.active = active
            self.bed = bed
            self.score = score
            self.checksumText = checksumText
            self.pinned = pinned
            self.contactEmail = contactEmail
            self.endsAt = endsAt
            self.updatedAt = updatedAt
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityLedgerView(_ item: EligibilityLedger) -> EligibilityLedgerView {
        return EligibilityLedgerView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 80),
            active: "\(item.active)",
            bed: item.bed,
            score: String(format: "%.2f", item.score),
            checksumText: Kit.Text.truncate(item.checksum, limit: 40),
            pinned: "\(item.pinned)",
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            endsAt: String(item.endsAt),
            updatedAt: String(item.updatedAt),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityLedgerViews(_ items: [EligibilityLedger]) -> [EligibilityLedgerView] {
        var views: [EligibilityLedgerView] = []
        for item in items {
            views.append(toEligibilityLedgerView(item))
        }
        return views
    }

    static func sumEligibilityLedgerView(_ view: EligibilityLedgerView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedScore + Double(parsedEndsAt) + Double(parsedUpdatedAt)
    }
}
