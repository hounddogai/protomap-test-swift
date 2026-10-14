import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a task schedule.
    final class TaskScheduleView {
        var code: String
        var name: String
        var minimumText: String
        var notes: String
        var statusLabel: String

        init(code: String, name: String, minimumText: String, notes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimumText = minimumText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toTaskScheduleView(_ item: TaskSchedule) -> TaskScheduleView {
        return TaskScheduleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            minimumText: String(format: "%.2f", item.minimum),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTaskScheduleViews(_ items: [TaskSchedule]) -> [TaskScheduleView] {
        var views: [TaskScheduleView] = []
        for item in items {
            views.append(toTaskScheduleView(item))
        }
        return views
    }

    static func sumTaskScheduleView(_ view: TaskScheduleView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
