import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual skill mix schedule.
    final class ManualSkillMixScheduleView {
        var code: String
        var labelText: String
        var name: String
        var rate: String
        var minimum: String
        var versionText: String
        var budgetText: String
        var windowDays: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, labelText: String, name: String, rate: String, minimum: String, versionText: String, budgetText: String, windowDays: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.name = name
            self.rate = rate
            self.minimum = minimum
            self.versionText = versionText
            self.budgetText = budgetText
            self.windowDays = windowDays
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toManualSkillMixScheduleView(_ item: ManualSkillMixSchedule) -> ManualSkillMixScheduleView {
        return ManualSkillMixScheduleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            name: item.name,
            rate: String(format: "%.2f", item.rate),
            minimum: String(format: "%.2f", item.minimum),
            versionText: String(item.version),
            budgetText: String(format: "%.2f", item.budget),
            windowDays: String(item.windowDays),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualSkillMixScheduleViews(_ items: [ManualSkillMixSchedule]) -> [ManualSkillMixScheduleView] {
        var views: [ManualSkillMixScheduleView] = []
        for item in items {
            views.append(toManualSkillMixScheduleView(item))
        }
        return views
    }

    static func sumManualSkillMixScheduleView(_ view: ManualSkillMixScheduleView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedRate + parsedMinimum + Double(parsedVersion)
    }
}
