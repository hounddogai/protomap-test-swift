import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global task schedule.
    final class GlobalTaskScheduleView {
        var codeText: String
        var label: String
        var channel: String
        var expiresAt: String
        var active: String
        var approved: String
        var timezoneText: String
        var statusLabel: String

        init(codeText: String, label: String, channel: String, expiresAt: String, active: String, approved: String, timezoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.channel = channel
            self.expiresAt = expiresAt
            self.active = active
            self.approved = approved
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalTaskScheduleView(_ item: GlobalTaskSchedule) -> GlobalTaskScheduleView {
        return GlobalTaskScheduleView(
            codeText: item.code,
            label: item.label,
            channel: item.channel,
            expiresAt: String(item.expiresAt),
            active: "\(item.active)",
            approved: "\(item.approved)",
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalTaskScheduleViews(_ items: [GlobalTaskSchedule]) -> [GlobalTaskScheduleView] {
        var views: [GlobalTaskScheduleView] = []
        for item in items {
            views.append(toGlobalTaskScheduleView(item))
        }
        return views
    }

    static func sumGlobalTaskScheduleView(_ view: GlobalTaskScheduleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
