import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix schedule.
    final class SkillMixScheduleView {
        var code: String
        var nameText: String
        var category: String
        var procedureCode: String
        var copay: String
        var currencyText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, nameText: String, category: String, procedureCode: String, copay: String, currencyText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.category = category
            self.procedureCode = procedureCode
            self.copay = copay
            self.currencyText = currencyText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixScheduleView(_ item: SkillMixSchedule) -> SkillMixScheduleView {
        return SkillMixScheduleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            nameText: item.name,
            category: Kit.Text.truncate(item.category, limit: 80),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            copay: String(format: "%.2f", item.copay),
            currencyText: Kit.Text.truncate(item.currency, limit: 80),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixScheduleViews(_ items: [SkillMixSchedule]) -> [SkillMixScheduleView] {
        var views: [SkillMixScheduleView] = []
        for item in items {
            views.append(toSkillMixScheduleView(item))
        }
        return views
    }

    static func sumSkillMixScheduleView(_ view: SkillMixScheduleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCopay + Double(parsedDurationMinutes)
    }
}
