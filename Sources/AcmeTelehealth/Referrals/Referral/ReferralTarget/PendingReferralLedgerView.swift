import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending referral ledger.
    final class PendingReferralLedgerView {
        var code: String
        var label: String
        var cost: String
        var revision: String
        var retries: String
        var titleText: String
        var endsAt: String
        var name: String
        var description: String
        var margin: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, cost: String, revision: String, retries: String, titleText: String, endsAt: String, name: String, description: String, margin: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.cost = cost
            self.revision = revision
            self.retries = retries
            self.titleText = titleText
            self.endsAt = endsAt
            self.name = name
            self.description = description
            self.margin = margin
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReferralLedgerView(_ item: PendingReferralLedger) -> PendingReferralLedgerView {
        return PendingReferralLedgerView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            revision: String(item.revision),
            retries: String(item.retries),
            titleText: item.title,
            endsAt: String(item.endsAt),
            name: Kit.Text.truncate(item.name, limit: 120),
            description: item.description,
            margin: String(format: "%.2f", item.margin),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReferralLedgerViews(_ items: [PendingReferralLedger]) -> [PendingReferralLedgerView] {
        var views: [PendingReferralLedgerView] = []
        for item in items {
            views.append(toPendingReferralLedgerView(item))
        }
        return views
    }

    static func sumPendingReferralLedgerView(_ view: PendingReferralLedgerView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedCost + Double(parsedRevision) + Double(parsedRetries)
    }
}
