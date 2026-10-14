import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix milestone.
    final class SkillMixMilestoneView {
        var codeText: String
        var title: String
        var sourceText: String
        var graceDays: String
        var weight: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, title: String, sourceText: String, graceDays: String, weight: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.sourceText = sourceText
            self.graceDays = graceDays
            self.weight = weight
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixMilestoneView(_ item: SkillMixMilestone) -> SkillMixMilestoneView {
        return SkillMixMilestoneView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            sourceText: item.source,
            graceDays: String(item.graceDays),
            weight: String(format: "%.2f", item.weight),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixMilestoneViews(_ items: [SkillMixMilestone]) -> [SkillMixMilestoneView] {
        var views: [SkillMixMilestoneView] = []
        for item in items {
            views.append(toSkillMixMilestoneView(item))
        }
        return views
    }

    static func sumSkillMixMilestoneView(_ view: SkillMixMilestoneView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedGraceDays) + parsedWeight + parsedFloorValue
    }
}
