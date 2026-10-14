import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix metric.
    final class SkillMixMetricView {
        var code: String
        var titleText: String
        var ownerID: String
        var startsAt: String
        var categoryText: String
        var label: String
        var statusLabel: String

        init(code: String, titleText: String, ownerID: String, startsAt: String, categoryText: String, label: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ownerID = ownerID
            self.startsAt = startsAt
            self.categoryText = categoryText
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixMetricView(_ item: SkillMixMetric) -> SkillMixMetricView {
        return SkillMixMetricView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: Kit.Text.truncate(item.title, limit: 64),
            ownerID: item.ownerID,
            startsAt: String(item.startsAt),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixMetricViews(_ items: [SkillMixMetric]) -> [SkillMixMetricView] {
        var views: [SkillMixMetricView] = []
        for item in items {
            views.append(toSkillMixMetricView(item))
        }
        return views
    }

    static func sumSkillMixMetricView(_ view: SkillMixMetricView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
