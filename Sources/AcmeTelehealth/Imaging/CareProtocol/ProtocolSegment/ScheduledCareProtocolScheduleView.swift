import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled care protocol schedule.
    final class ScheduledCareProtocolScheduleView {
        var codeText: String
        var nameText: String
        var procedureCode: String
        var durationMinutesText: String
        var ratio: String
        var timezoneText: String
        var copay: String
        var archivedText: String
        var statusLabel: String

        init(codeText: String, nameText: String, procedureCode: String, durationMinutesText: String, ratio: String, timezoneText: String, copay: String, archivedText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.procedureCode = procedureCode
            self.durationMinutesText = durationMinutesText
            self.ratio = ratio
            self.timezoneText = timezoneText
            self.copay = copay
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledCareProtocolScheduleView(_ item: ScheduledCareProtocolSchedule) -> ScheduledCareProtocolScheduleView {
        return ScheduledCareProtocolScheduleView(
            codeText: item.code,
            nameText: item.name,
            procedureCode: item.procedureCode,
            durationMinutesText: String(item.durationMinutes),
            ratio: String(format: "%.2f", item.ratio),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 64),
            copay: String(format: "%.2f", item.copay),
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledCareProtocolScheduleViews(_ items: [ScheduledCareProtocolSchedule]) -> [ScheduledCareProtocolScheduleView] {
        var views: [ScheduledCareProtocolScheduleView] = []
        for item in items {
            views.append(toScheduledCareProtocolScheduleView(item))
        }
        return views
    }

    static func sumScheduledCareProtocolScheduleView(_ view: ScheduledCareProtocolScheduleView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedDurationMinutes) + parsedRatio + parsedCopay
    }
}
