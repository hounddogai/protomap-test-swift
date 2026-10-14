import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global network schedule.
    final class GlobalNetworkScheduleView {
        var code: String
        var nameText: String
        var durationMinutesText: String
        var contactEmail: String
        var externalRef: String
        var region: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, nameText: String, durationMinutesText: String, contactEmail: String, externalRef: String, region: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.durationMinutesText = durationMinutesText
            self.contactEmail = contactEmail
            self.externalRef = externalRef
            self.region = region
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalNetworkScheduleView(_ item: GlobalNetworkSchedule) -> GlobalNetworkScheduleView {
        return GlobalNetworkScheduleView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            durationMinutesText: String(item.durationMinutes),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            region: item.region,
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalNetworkScheduleViews(_ items: [GlobalNetworkSchedule]) -> [GlobalNetworkScheduleView] {
        var views: [GlobalNetworkScheduleView] = []
        for item in items {
            views.append(toGlobalNetworkScheduleView(item))
        }
        return views
    }

    static func sumGlobalNetworkScheduleView(_ view: GlobalNetworkScheduleView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedDurationMinutes)
    }
}
