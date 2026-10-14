import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled recall audit.
    final class ScheduledRecallAuditView {
        var code: String
        var labelText: String
        var durationMinutesText: String
        var minimum: String
        var allergy: String
        var archived: String
        var score: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, labelText: String, durationMinutesText: String, minimum: String, allergy: String, archived: String, score: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.durationMinutesText = durationMinutesText
            self.minimum = minimum
            self.allergy = allergy
            self.archived = archived
            self.score = score
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledRecallAuditView(_ item: ScheduledRecallAudit) -> ScheduledRecallAuditView {
        return ScheduledRecallAuditView(
            code: item.code,
            labelText: item.label,
            durationMinutesText: String(item.durationMinutes),
            minimum: String(format: "%.2f", item.minimum),
            allergy: item.allergy,
            archived: "\(item.archived)",
            score: String(format: "%.2f", item.score),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledRecallAuditViews(_ items: [ScheduledRecallAudit]) -> [ScheduledRecallAuditView] {
        var views: [ScheduledRecallAuditView] = []
        for item in items {
            views.append(toScheduledRecallAuditView(item))
        }
        return views
    }

    static func sumScheduledRecallAuditView(_ view: ScheduledRecallAuditView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedDurationMinutes) + parsedMinimum + parsedScore
    }
}
