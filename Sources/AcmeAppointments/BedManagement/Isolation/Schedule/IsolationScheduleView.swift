import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation schedule.
    final class IsolationScheduleView {
        var code: String
        var titleText: String
        var pinnedText: String
        var clinicianID: String
        var procedureCodeText: String
        var version: String
        var summary: String
        var durationMinutes: String
        var capacity: String
        var priorityText: String
        var approved: String
        var statusLabel: String

        init(code: String, titleText: String, pinnedText: String, clinicianID: String, procedureCodeText: String, version: String, summary: String, durationMinutes: String, capacity: String, priorityText: String, approved: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.pinnedText = pinnedText
            self.clinicianID = clinicianID
            self.procedureCodeText = procedureCodeText
            self.version = version
            self.summary = summary
            self.durationMinutes = durationMinutes
            self.capacity = capacity
            self.priorityText = priorityText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationScheduleView(_ item: IsolationSchedule) -> IsolationScheduleView {
        return IsolationScheduleView(
            code: item.code,
            titleText: item.title,
            pinnedText: "\(item.pinned)",
            clinicianID: item.clinicianID,
            procedureCodeText: item.procedureCode,
            version: String(item.version),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            durationMinutes: String(item.durationMinutes),
            capacity: String(item.capacity),
            priorityText: String(item.priority),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationScheduleViews(_ items: [IsolationSchedule]) -> [IsolationScheduleView] {
        var views: [IsolationScheduleView] = []
        for item in items {
            views.append(toIsolationScheduleView(item))
        }
        return views
    }

    static func sumIsolationScheduleView(_ view: IsolationScheduleView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedVersion) + Double(parsedDurationMinutes) + Double(parsedCapacity)
    }
}
