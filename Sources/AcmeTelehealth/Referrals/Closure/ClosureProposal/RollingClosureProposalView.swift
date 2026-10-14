import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling closure proposal.
    final class RollingClosureProposalView {
        var codeText: String
        var labelText: String
        var reviewer: String
        var scoreText: String
        var limitText: String
        var pinnedText: String
        var rateText: String
        var archivedText: String
        var visible: String
        var unitText: String
        var allergyText: String
        var statusLabel: String

        init(codeText: String, labelText: String, reviewer: String, scoreText: String, limitText: String, pinnedText: String, rateText: String, archivedText: String, visible: String, unitText: String, allergyText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.reviewer = reviewer
            self.scoreText = scoreText
            self.limitText = limitText
            self.pinnedText = pinnedText
            self.rateText = rateText
            self.archivedText = archivedText
            self.visible = visible
            self.unitText = unitText
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingClosureProposalView(_ item: RollingClosureProposal) -> RollingClosureProposalView {
        return RollingClosureProposalView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            reviewer: item.reviewer,
            scoreText: String(format: "%.2f", item.score),
            limitText: String(item.limit),
            pinnedText: "\(item.pinned)",
            rateText: String(format: "%.2f", item.rate),
            archivedText: "\(item.archived)",
            visible: "\(item.visible)",
            unitText: Kit.Text.truncate(item.unit, limit: 40),
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingClosureProposalViews(_ items: [RollingClosureProposal]) -> [RollingClosureProposalView] {
        var views: [RollingClosureProposalView] = []
        for item in items {
            views.append(toRollingClosureProposalView(item))
        }
        return views
    }

    static func sumRollingClosureProposalView(_ view: RollingClosureProposalView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedScore + Double(parsedLimit) + parsedRate
    }
}
