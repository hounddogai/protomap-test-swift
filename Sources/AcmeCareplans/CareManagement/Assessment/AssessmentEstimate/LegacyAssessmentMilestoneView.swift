import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy assessment milestone.
    final class LegacyAssessmentMilestoneView {
        var code: String
        var name: String
        var budgetText: String
        var descriptionText: String
        var checksum: String
        var durationMinutesText: String
        var region: String
        var ceilingText: String
        var unitText: String
        var statusLabel: String

        init(code: String, name: String, budgetText: String, descriptionText: String, checksum: String, durationMinutesText: String, region: String, ceilingText: String, unitText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budgetText = budgetText
            self.descriptionText = descriptionText
            self.checksum = checksum
            self.durationMinutesText = durationMinutesText
            self.region = region
            self.ceilingText = ceilingText
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAssessmentMilestoneView(_ item: LegacyAssessmentMilestone) -> LegacyAssessmentMilestoneView {
        return LegacyAssessmentMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            budgetText: String(format: "%.2f", item.budget),
            descriptionText: item.description,
            checksum: item.checksum,
            durationMinutesText: String(item.durationMinutes),
            region: item.region,
            ceilingText: String(format: "%.2f", item.ceiling),
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAssessmentMilestoneViews(_ items: [LegacyAssessmentMilestone]) -> [LegacyAssessmentMilestoneView] {
        var views: [LegacyAssessmentMilestoneView] = []
        for item in items {
            views.append(toLegacyAssessmentMilestoneView(item))
        }
        return views
    }

    static func sumLegacyAssessmentMilestoneView(_ view: LegacyAssessmentMilestoneView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedBudget + Double(parsedDurationMinutes) + parsedCeiling
    }
}
