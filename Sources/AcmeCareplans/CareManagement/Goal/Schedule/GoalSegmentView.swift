import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal segment.
    final class GoalSegmentView {
        var code: String
        var title: String
        var contactEmail: String
        var pinned: String
        var country: String
        var windowDaysText: String
        var threshold: String
        var statusLabel: String

        init(code: String, title: String, contactEmail: String, pinned: String, country: String, windowDaysText: String, threshold: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.country = country
            self.windowDaysText = windowDaysText
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toGoalSegmentView(_ item: GoalSegment) -> GoalSegmentView {
        return GoalSegmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 120),
            contactEmail: item.contactEmail,
            pinned: "\(item.pinned)",
            country: item.country,
            windowDaysText: String(item.windowDays),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalSegmentViews(_ items: [GoalSegment]) -> [GoalSegmentView] {
        var views: [GoalSegmentView] = []
        for item in items {
            views.append(toGoalSegmentView(item))
        }
        return views
    }

    static func sumGoalSegmentView(_ view: GoalSegmentView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedWindowDays) + parsedThreshold
    }
}
