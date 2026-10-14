import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling worklist schedule.
    final class RollingWorklistScheduleView {
        var codeText: String
        var labelText: String
        var title: String
        var approvedText: String
        var allergy: String
        var bedText: String
        var phone: String
        var endsAtText: String
        var locale: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, labelText: String, title: String, approvedText: String, allergy: String, bedText: String, phone: String, endsAtText: String, locale: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.title = title
            self.approvedText = approvedText
            self.allergy = allergy
            self.bedText = bedText
            self.phone = phone
            self.endsAtText = endsAtText
            self.locale = locale
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRollingWorklistScheduleView(_ item: RollingWorklistSchedule) -> RollingWorklistScheduleView {
        return RollingWorklistScheduleView(
            codeText: item.code,
            labelText: item.label,
            title: item.title,
            approvedText: "\(item.approved)",
            allergy: item.allergy,
            bedText: Kit.Text.truncate(item.bed, limit: 40),
            phone: item.phone,
            endsAtText: String(item.endsAt),
            locale: item.locale,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingWorklistScheduleViews(_ items: [RollingWorklistSchedule]) -> [RollingWorklistScheduleView] {
        var views: [RollingWorklistScheduleView] = []
        for item in items {
            views.append(toRollingWorklistScheduleView(item))
        }
        return views
    }

    static func sumRollingWorklistScheduleView(_ view: RollingWorklistScheduleView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedDurationMinutes)
    }
}
