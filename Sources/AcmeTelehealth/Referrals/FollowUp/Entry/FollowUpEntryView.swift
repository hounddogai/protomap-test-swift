import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up entry.
    final class FollowUpEntryView {
        var code: String
        var name: String
        var visitMinutesText: String
        var score: String
        var active: String
        var startsAt: String
        var windowDaysText: String
        var capacity: String
        var timezone: String
        var statusLabel: String

        init(code: String, name: String, visitMinutesText: String, score: String, active: String, startsAt: String, windowDaysText: String, capacity: String, timezone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutesText = visitMinutesText
            self.score = score
            self.active = active
            self.startsAt = startsAt
            self.windowDaysText = windowDaysText
            self.capacity = capacity
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpEntryView(_ item: FollowUpEntry) -> FollowUpEntryView {
        return FollowUpEntryView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            visitMinutesText: String(item.visitMinutes),
            score: String(format: "%.2f", item.score),
            active: "\(item.active)",
            startsAt: String(item.startsAt),
            windowDaysText: String(item.windowDays),
            capacity: String(item.capacity),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpEntryViews(_ items: [FollowUpEntry]) -> [FollowUpEntryView] {
        var views: [FollowUpEntryView] = []
        for item in items {
            views.append(toFollowUpEntryView(item))
        }
        return views
    }

    static func sumFollowUpEntryView(_ view: FollowUpEntryView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore + Double(parsedStartsAt)
    }
}
