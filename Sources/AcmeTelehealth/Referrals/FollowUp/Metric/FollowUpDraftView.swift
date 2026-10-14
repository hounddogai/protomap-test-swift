import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up draft.
    final class FollowUpDraftView {
        var codeText: String
        var label: String
        var score: String
        var unit: String
        var payerText: String
        var contactEmail: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, label: String, score: String, unit: String, payerText: String, contactEmail: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.score = score
            self.unit = unit
            self.payerText = payerText
            self.contactEmail = contactEmail
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpDraftView(_ item: FollowUpDraft) -> FollowUpDraftView {
        return FollowUpDraftView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            score: String(format: "%.2f", item.score),
            unit: item.unit,
            payerText: Kit.Text.truncate(item.payer, limit: 40),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpDraftViews(_ items: [FollowUpDraft]) -> [FollowUpDraftView] {
        var views: [FollowUpDraftView] = []
        for item in items {
            views.append(toFollowUpDraftView(item))
        }
        return views
    }

    static func sumFollowUpDraftView(_ view: FollowUpDraftView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedScore + parsedCeiling
    }
}
