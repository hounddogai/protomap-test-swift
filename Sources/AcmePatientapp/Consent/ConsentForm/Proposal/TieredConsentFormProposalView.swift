import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered consent form proposal.
    final class TieredConsentFormProposalView {
        var codeText: String
        var labelText: String
        var archived: String
        var priorityText: String
        var score: String
        var statusLabel: String

        init(codeText: String, labelText: String, archived: String, priorityText: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.archived = archived
            self.priorityText = priorityText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toTieredConsentFormProposalView(_ item: TieredConsentFormProposal) -> TieredConsentFormProposalView {
        return TieredConsentFormProposalView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            archived: "\(item.archived)",
            priorityText: String(item.priority),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredConsentFormProposalViews(_ items: [TieredConsentFormProposal]) -> [TieredConsentFormProposalView] {
        var views: [TieredConsentFormProposalView] = []
        for item in items {
            views.append(toTieredConsentFormProposalView(item))
        }
        return views
    }

    static func sumTieredConsentFormProposalView(_ view: TieredConsentFormProposalView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedPriority) + parsedScore
    }
}
