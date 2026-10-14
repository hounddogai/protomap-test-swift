import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up proposal.
    final class FollowUpProposalView {
        var codeText: String
        var title: String
        var ceiling: String
        var encounterID: String
        var startsAt: String
        var limit: String
        var endsAt: String
        var refillsText: String
        var statusLabel: String

        init(codeText: String, title: String, ceiling: String, encounterID: String, startsAt: String, limit: String, endsAt: String, refillsText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ceiling = ceiling
            self.encounterID = encounterID
            self.startsAt = startsAt
            self.limit = limit
            self.endsAt = endsAt
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpProposalView(_ item: FollowUpProposal) -> FollowUpProposalView {
        return FollowUpProposalView(
            codeText: item.code,
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            encounterID: item.encounterID,
            startsAt: String(item.startsAt),
            limit: String(item.limit),
            endsAt: String(item.endsAt),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpProposalViews(_ items: [FollowUpProposal]) -> [FollowUpProposalView] {
        var views: [FollowUpProposalView] = []
        for item in items {
            views.append(toFollowUpProposalView(item))
        }
        return views
    }

    static func sumFollowUpProposalView(_ view: FollowUpProposalView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedCeiling + Double(parsedStartsAt) + Double(parsedLimit)
    }
}
