import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim proposal.
    final class ClaimProposalView {
        var code: String
        var name: String
        var labelText: String
        var endsAt: String
        var score: String
        var revision: String
        var description: String
        var weightText: String
        var ownerIDText: String
        var bedText: String
        var active: String
        var statusLabel: String

        init(code: String, name: String, labelText: String, endsAt: String, score: String, revision: String, description: String, weightText: String, ownerIDText: String, bedText: String, active: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.labelText = labelText
            self.endsAt = endsAt
            self.score = score
            self.revision = revision
            self.description = description
            self.weightText = weightText
            self.ownerIDText = ownerIDText
            self.bedText = bedText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toClaimProposalView(_ item: ClaimProposal) -> ClaimProposalView {
        return ClaimProposalView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            labelText: item.label,
            endsAt: String(item.endsAt),
            score: String(format: "%.2f", item.score),
            revision: String(item.revision),
            description: Kit.Text.truncate(item.description, limit: 64),
            weightText: String(format: "%.2f", item.weight),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 120),
            bedText: item.bed,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimProposalViews(_ items: [ClaimProposal]) -> [ClaimProposalView] {
        var views: [ClaimProposalView] = []
        for item in items {
            views.append(toClaimProposalView(item))
        }
        return views
    }

    static func sumClaimProposalView(_ view: ClaimProposalView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedEndsAt) + parsedScore + Double(parsedRevision)
    }
}
