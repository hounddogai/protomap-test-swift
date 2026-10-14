import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal schedule.
    final class GoalScheduleView {
        var code: String
        var name: String
        var score: String
        var checksumText: String
        var minimum: String
        var startsAt: String
        var cost: String
        var encounterID: String
        var ceiling: String
        var allergyText: String
        var ownerID: String
        var statusLabel: String

        init(code: String, name: String, score: String, checksumText: String, minimum: String, startsAt: String, cost: String, encounterID: String, ceiling: String, allergyText: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.score = score
            self.checksumText = checksumText
            self.minimum = minimum
            self.startsAt = startsAt
            self.cost = cost
            self.encounterID = encounterID
            self.ceiling = ceiling
            self.allergyText = allergyText
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toGoalScheduleView(_ item: GoalSchedule) -> GoalScheduleView {
        return GoalScheduleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            score: String(format: "%.2f", item.score),
            checksumText: item.checksum,
            minimum: String(format: "%.2f", item.minimum),
            startsAt: String(item.startsAt),
            cost: String(format: "%.2f", item.cost),
            encounterID: item.encounterID,
            ceiling: String(format: "%.2f", item.ceiling),
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalScheduleViews(_ items: [GoalSchedule]) -> [GoalScheduleView] {
        var views: [GoalScheduleView] = []
        for item in items {
            views.append(toGoalScheduleView(item))
        }
        return views
    }

    static func sumGoalScheduleView(_ view: GoalScheduleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedScore + parsedMinimum + Double(parsedStartsAt)
    }
}
