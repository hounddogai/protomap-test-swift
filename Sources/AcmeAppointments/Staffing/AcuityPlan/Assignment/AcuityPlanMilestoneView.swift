import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan milestone.
    final class AcuityPlanMilestoneView {
        var codeText: String
        var label: String
        var ownerID: String
        var scoreText: String
        var rateText: String
        var statusLabel: String

        init(codeText: String, label: String, ownerID: String, scoreText: String, rateText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ownerID = ownerID
            self.scoreText = scoreText
            self.rateText = rateText
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanMilestoneView(_ item: AcuityPlanMilestone) -> AcuityPlanMilestoneView {
        return AcuityPlanMilestoneView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            scoreText: String(format: "%.2f", item.score),
            rateText: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanMilestoneViews(_ items: [AcuityPlanMilestone]) -> [AcuityPlanMilestoneView] {
        var views: [AcuityPlanMilestoneView] = []
        for item in items {
            views.append(toAcuityPlanMilestoneView(item))
        }
        return views
    }

    static func sumAcuityPlanMilestoneView(_ view: AcuityPlanMilestoneView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedScore + parsedRate
    }
}
