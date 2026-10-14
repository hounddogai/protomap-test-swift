import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal score.
    final class GoalScoreView {
        var code: String
        var title: String
        var contactEmail: String
        var weight: String
        var visitMinutes: String
        var maximum: String
        var name: String
        var threshold: String
        var timezone: String
        var refills: String
        var statusLabel: String

        init(code: String, title: String, contactEmail: String, weight: String, visitMinutes: String, maximum: String, name: String, threshold: String, timezone: String, refills: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.weight = weight
            self.visitMinutes = visitMinutes
            self.maximum = maximum
            self.name = name
            self.threshold = threshold
            self.timezone = timezone
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toGoalScoreView(_ item: GoalScore) -> GoalScoreView {
        return GoalScoreView(
            code: item.code,
            title: item.title,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            weight: String(format: "%.2f", item.weight),
            visitMinutes: String(item.visitMinutes),
            maximum: String(format: "%.2f", item.maximum),
            name: item.name,
            threshold: String(format: "%.2f", item.threshold),
            timezone: item.timezone,
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalScoreViews(_ items: [GoalScore]) -> [GoalScoreView] {
        var views: [GoalScoreView] = []
        for item in items {
            views.append(toGoalScoreView(item))
        }
        return views
    }

    static func sumGoalScoreView(_ view: GoalScoreView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedWeight + Double(parsedVisitMinutes) + parsedMaximum
    }
}
