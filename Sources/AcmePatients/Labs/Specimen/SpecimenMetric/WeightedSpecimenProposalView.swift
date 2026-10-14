import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted specimen proposal.
    final class WeightedSpecimenProposalView {
        var codeText: String
        var title: String
        var facility: String
        var name: String
        var startsAtText: String
        var statusLabel: String

        init(codeText: String, title: String, facility: String, name: String, startsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.facility = facility
            self.name = name
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSpecimenProposalView(_ item: WeightedSpecimenProposal) -> WeightedSpecimenProposalView {
        return WeightedSpecimenProposalView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            facility: Kit.Text.truncate(item.facility, limit: 120),
            name: item.name,
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSpecimenProposalViews(_ items: [WeightedSpecimenProposal]) -> [WeightedSpecimenProposalView] {
        var views: [WeightedSpecimenProposalView] = []
        for item in items {
            views.append(toWeightedSpecimenProposalView(item))
        }
        return views
    }

    static func sumWeightedSpecimenProposalView(_ view: WeightedSpecimenProposalView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
