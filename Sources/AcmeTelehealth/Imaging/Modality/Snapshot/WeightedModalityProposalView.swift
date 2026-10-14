import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted modality proposal.
    final class WeightedModalityProposalView {
        var code: String
        var nameText: String
        var startsAt: String
        var active: String
        var region: String
        var externalRef: String
        var statusLabel: String

        init(code: String, nameText: String, startsAt: String, active: String, region: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.startsAt = startsAt
            self.active = active
            self.region = region
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedModalityProposalView(_ item: WeightedModalityProposal) -> WeightedModalityProposalView {
        return WeightedModalityProposalView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            startsAt: String(item.startsAt),
            active: "\(item.active)",
            region: Kit.Text.truncate(item.region, limit: 120),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedModalityProposalViews(_ items: [WeightedModalityProposal]) -> [WeightedModalityProposalView] {
        var views: [WeightedModalityProposalView] = []
        for item in items {
            views.append(toWeightedModalityProposalView(item))
        }
        return views
    }

    static func sumWeightedModalityProposalView(_ view: WeightedModalityProposalView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
