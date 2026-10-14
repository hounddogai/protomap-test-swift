import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional result schedule.
    final class RegionalResultScheduleView {
        var code: String
        var name: String
        var pinnedText: String
        var contactEmailText: String
        var limit: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, name: String, pinnedText: String, contactEmailText: String, limit: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinnedText = pinnedText
            self.contactEmailText = contactEmailText
            self.limit = limit
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalResultScheduleView(_ item: RegionalResultSchedule) -> RegionalResultScheduleView {
        return RegionalResultScheduleView(
            code: item.code,
            name: item.name,
            pinnedText: "\(item.pinned)",
            contactEmailText: item.contactEmail,
            limit: String(item.limit),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalResultScheduleViews(_ items: [RegionalResultSchedule]) -> [RegionalResultScheduleView] {
        var views: [RegionalResultScheduleView] = []
        for item in items {
            views.append(toRegionalResultScheduleView(item))
        }
        return views
    }

    static func sumRegionalResultScheduleView(_ view: RegionalResultScheduleView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
