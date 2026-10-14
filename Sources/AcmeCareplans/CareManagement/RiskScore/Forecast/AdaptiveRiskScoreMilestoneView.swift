import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a adaptive risk score milestone.
    final class AdaptiveRiskScoreMilestoneView {
        var code: String
        var title: String
        var ceiling: String
        var country: String
        var sequence: String
        var ownerID: String
        var costText: String
        var summaryText: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, country: String, sequence: String, ownerID: String, costText: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.country = country
            self.sequence = sequence
            self.ownerID = ownerID
            self.costText = costText
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRiskScoreMilestoneView(_ item: AdaptiveRiskScoreMilestone) -> AdaptiveRiskScoreMilestoneView {
        return AdaptiveRiskScoreMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            country: item.country,
            sequence: String(item.sequence),
            ownerID: item.ownerID,
            costText: String(format: "%.2f", item.cost),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRiskScoreMilestoneViews(_ items: [AdaptiveRiskScoreMilestone]) -> [AdaptiveRiskScoreMilestoneView] {
        var views: [AdaptiveRiskScoreMilestoneView] = []
        for item in items {
            views.append(toAdaptiveRiskScoreMilestoneView(item))
        }
        return views
    }

    static func sumAdaptiveRiskScoreMilestoneView(_ view: AdaptiveRiskScoreMilestoneView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCeiling + Double(parsedSequence) + parsedCost
    }
}
