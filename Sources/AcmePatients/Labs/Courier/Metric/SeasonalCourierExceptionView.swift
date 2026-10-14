import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal courier exception.
    final class SeasonalCourierExceptionView {
        var code: String
        var title: String
        var contactEmail: String
        var durationMinutes: String
        var bed: String
        var timezoneText: String
        var statusLabel: String

        init(code: String, title: String, contactEmail: String, durationMinutes: String, bed: String, timezoneText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.durationMinutes = durationMinutes
            self.bed = bed
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCourierExceptionView(_ item: SeasonalCourierException) -> SeasonalCourierExceptionView {
        return SeasonalCourierExceptionView(
            code: item.code,
            title: item.title,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            durationMinutes: String(item.durationMinutes),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            timezoneText: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCourierExceptionViews(_ items: [SeasonalCourierException]) -> [SeasonalCourierExceptionView] {
        var views: [SeasonalCourierExceptionView] = []
        for item in items {
            views.append(toSeasonalCourierExceptionView(item))
        }
        return views
    }

    static func sumSeasonalCourierExceptionView(_ view: SeasonalCourierExceptionView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}
