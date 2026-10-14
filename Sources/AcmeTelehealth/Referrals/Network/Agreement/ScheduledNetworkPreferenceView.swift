import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled network preference.
    final class ScheduledNetworkPreferenceView {
        var code: String
        var nameText: String
        var attempts: String
        var title: String
        var summary: String
        var bed: String
        var localeText: String
        var facility: String
        var statusLabel: String

        init(code: String, nameText: String, attempts: String, title: String, summary: String, bed: String, localeText: String, facility: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.attempts = attempts
            self.title = title
            self.summary = summary
            self.bed = bed
            self.localeText = localeText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledNetworkPreferenceView(_ item: ScheduledNetworkPreference) -> ScheduledNetworkPreferenceView {
        return ScheduledNetworkPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            attempts: String(item.attempts),
            title: item.title,
            summary: item.summary,
            bed: item.bed,
            localeText: item.locale,
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledNetworkPreferenceViews(_ items: [ScheduledNetworkPreference]) -> [ScheduledNetworkPreferenceView] {
        var views: [ScheduledNetworkPreferenceView] = []
        for item in items {
            views.append(toScheduledNetworkPreferenceView(item))
        }
        return views
    }

    static func sumScheduledNetworkPreferenceView(_ view: ScheduledNetworkPreferenceView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
