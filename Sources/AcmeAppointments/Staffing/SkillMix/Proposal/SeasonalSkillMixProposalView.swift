import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a seasonal skill mix proposal.
    final class SeasonalSkillMixProposalView {
        var code: String
        var name: String
        var summaryText: String
        var regionText: String
        var refills: String
        var ratio: String
        var budget: String
        var capacity: String
        var statusLabel: String

        init(code: String, name: String, summaryText: String, regionText: String, refills: String, ratio: String, budget: String, capacity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.summaryText = summaryText
            self.regionText = regionText
            self.refills = refills
            self.ratio = ratio
            self.budget = budget
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSkillMixProposalView(_ item: SeasonalSkillMixProposal) -> SeasonalSkillMixProposalView {
        return SeasonalSkillMixProposalView(
            code: item.code,
            name: item.name,
            summaryText: item.summary,
            regionText: Kit.Text.truncate(item.region, limit: 80),
            refills: String(item.refills),
            ratio: String(format: "%.2f", item.ratio),
            budget: String(format: "%.2f", item.budget),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSkillMixProposalViews(_ items: [SeasonalSkillMixProposal]) -> [SeasonalSkillMixProposalView] {
        var views: [SeasonalSkillMixProposalView] = []
        for item in items {
            views.append(toSeasonalSkillMixProposalView(item))
        }
        return views
    }

    static func sumSeasonalSkillMixProposalView(_ view: SeasonalSkillMixProposalView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedRefills) + parsedRatio + parsedBudget
    }
}
