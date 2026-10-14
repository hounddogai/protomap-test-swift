import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted task schedule.
    final class WeightedTaskScheduleView {
        var codeText: String
        var titleText: String
        var notesText: String
        var durationMinutes: String
        var createdAtText: String
        var encounterID: String
        var retries: String
        var specialty: String
        var statusLabel: String

        init(codeText: String, titleText: String, notesText: String, durationMinutes: String, createdAtText: String, encounterID: String, retries: String, specialty: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.notesText = notesText
            self.durationMinutes = durationMinutes
            self.createdAtText = createdAtText
            self.encounterID = encounterID
            self.retries = retries
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedTaskScheduleView(_ item: WeightedTaskSchedule) -> WeightedTaskScheduleView {
        return WeightedTaskScheduleView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            notesText: item.notes,
            durationMinutes: String(item.durationMinutes),
            createdAtText: String(item.createdAt),
            encounterID: item.encounterID,
            retries: String(item.retries),
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedTaskScheduleViews(_ items: [WeightedTaskSchedule]) -> [WeightedTaskScheduleView] {
        var views: [WeightedTaskScheduleView] = []
        for item in items {
            views.append(toWeightedTaskScheduleView(item))
        }
        return views
    }

    static func sumWeightedTaskScheduleView(_ view: WeightedTaskScheduleView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedCreatedAt) + Double(parsedRetries)
    }
}
