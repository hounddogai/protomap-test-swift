import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled goal preference.
    final class ScheduledGoalPreferenceView {
        var code: String
        var name: String
        var budget: String
        var segmentText: String
        var timezone: String
        var country: String
        var procedureCode: String
        var weight: String
        var statusLabel: String

        init(code: String, name: String, budget: String, segmentText: String, timezone: String, country: String, procedureCode: String, weight: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budget = budget
            self.segmentText = segmentText
            self.timezone = timezone
            self.country = country
            self.procedureCode = procedureCode
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledGoalPreferenceView(_ item: ScheduledGoalPreference) -> ScheduledGoalPreferenceView {
        return ScheduledGoalPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 64),
            budget: String(format: "%.2f", item.budget),
            segmentText: Kit.Text.truncate(item.segment, limit: 80),
            timezone: item.timezone,
            country: item.country,
            procedureCode: item.procedureCode,
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledGoalPreferenceViews(_ items: [ScheduledGoalPreference]) -> [ScheduledGoalPreferenceView] {
        var views: [ScheduledGoalPreferenceView] = []
        for item in items {
            views.append(toScheduledGoalPreferenceView(item))
        }
        return views
    }

    static func sumScheduledGoalPreferenceView(_ view: ScheduledGoalPreferenceView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedBudget + parsedWeight
    }
}
