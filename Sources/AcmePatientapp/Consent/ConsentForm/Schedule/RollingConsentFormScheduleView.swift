import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling consent form schedule.
    final class RollingConsentFormScheduleView {
        var code: String
        var label: String
        var ward: String
        var countryText: String
        var clinicianID: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, label: String, ward: String, countryText: String, clinicianID: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ward = ward
            self.countryText = countryText
            self.clinicianID = clinicianID
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingConsentFormScheduleView(_ item: RollingConsentFormSchedule) -> RollingConsentFormScheduleView {
        return RollingConsentFormScheduleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            ward: item.ward,
            countryText: item.country,
            clinicianID: item.clinicianID,
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingConsentFormScheduleViews(_ items: [RollingConsentFormSchedule]) -> [RollingConsentFormScheduleView] {
        var views: [RollingConsentFormScheduleView] = []
        for item in items {
            views.append(toRollingConsentFormScheduleView(item))
        }
        return views
    }

    static func sumRollingConsentFormScheduleView(_ view: RollingConsentFormScheduleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
