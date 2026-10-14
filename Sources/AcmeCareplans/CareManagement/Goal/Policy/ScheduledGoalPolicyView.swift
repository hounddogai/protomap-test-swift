import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled goal policy.
    final class ScheduledGoalPolicyView {
        var codeText: String
        var title: String
        var durationMinutesText: String
        var endsAt: String
        var limit: String
        var localeText: String
        var updatedAt: String
        var ratioText: String
        var refillsText: String
        var priorityText: String
        var phone: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutesText: String, endsAt: String, limit: String, localeText: String, updatedAt: String, ratioText: String, refillsText: String, priorityText: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutesText = durationMinutesText
            self.endsAt = endsAt
            self.limit = limit
            self.localeText = localeText
            self.updatedAt = updatedAt
            self.ratioText = ratioText
            self.refillsText = refillsText
            self.priorityText = priorityText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledGoalPolicyView(_ item: ScheduledGoalPolicy) -> ScheduledGoalPolicyView {
        return ScheduledGoalPolicyView(
            codeText: item.code,
            title: item.title,
            durationMinutesText: String(item.durationMinutes),
            endsAt: String(item.endsAt),
            limit: String(item.limit),
            localeText: item.locale,
            updatedAt: String(item.updatedAt),
            ratioText: String(format: "%.2f", item.ratio),
            refillsText: String(item.refills),
            priorityText: String(item.priority),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledGoalPolicyViews(_ items: [ScheduledGoalPolicy]) -> [ScheduledGoalPolicyView] {
        var views: [ScheduledGoalPolicyView] = []
        for item in items {
            views.append(toScheduledGoalPolicyView(item))
        }
        return views
    }

    static func sumScheduledGoalPolicyView(_ view: ScheduledGoalPolicyView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedEndsAt) + Double(parsedLimit)
    }
}
