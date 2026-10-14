import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding proposal.
    final class RoundingProposalView {
        var code: String
        var name: String
        var sequence: String
        var summaryText: String
        var pinnedText: String
        var currencyText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, sequence: String, summaryText: String, pinnedText: String, currencyText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.summaryText = summaryText
            self.pinnedText = pinnedText
            self.currencyText = currencyText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingProposalView(_ item: RoundingProposal) -> RoundingProposalView {
        return RoundingProposalView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            sequence: String(item.sequence),
            summaryText: item.summary,
            pinnedText: "\(item.pinned)",
            currencyText: Kit.Text.truncate(item.currency, limit: 80),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingProposalViews(_ items: [RoundingProposal]) -> [RoundingProposalView] {
        var views: [RoundingProposalView] = []
        for item in items {
            views.append(toRoundingProposalView(item))
        }
        return views
    }

    static func sumRoundingProposalView(_ view: RoundingProposalView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedSequence) + Double(parsedEndsAt)
    }
}
