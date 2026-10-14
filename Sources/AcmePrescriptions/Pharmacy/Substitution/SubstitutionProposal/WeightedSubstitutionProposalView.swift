import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted substitution proposal.
    final class WeightedSubstitutionProposalView {
        var codeText: String
        var title: String
        var country: String
        var payer: String
        var timezone: String
        var facility: String
        var reviewer: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, title: String, country: String, payer: String, timezone: String, facility: String, reviewer: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.country = country
            self.payer = payer
            self.timezone = timezone
            self.facility = facility
            self.reviewer = reviewer
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSubstitutionProposalView(_ item: WeightedSubstitutionProposal) -> WeightedSubstitutionProposalView {
        return WeightedSubstitutionProposalView(
            codeText: item.code,
            title: item.title,
            country: Kit.Text.truncate(item.country, limit: 64),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            timezone: item.timezone,
            facility: item.facility,
            reviewer: item.reviewer,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSubstitutionProposalViews(_ items: [WeightedSubstitutionProposal]) -> [WeightedSubstitutionProposalView] {
        var views: [WeightedSubstitutionProposalView] = []
        for item in items {
            views.append(toWeightedSubstitutionProposalView(item))
        }
        return views
    }

    static func sumWeightedSubstitutionProposalView(_ view: WeightedSubstitutionProposalView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
