import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual consent form notice.
    final class ManualConsentFormNoticeView {
        var code: String
        var label: String
        var attempts: String
        var regionText: String
        var startsAt: String
        var wardText: String
        var statusLabel: String

        init(code: String, label: String, attempts: String, regionText: String, startsAt: String, wardText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.attempts = attempts
            self.regionText = regionText
            self.startsAt = startsAt
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toManualConsentFormNoticeView(_ item: ManualConsentFormNotice) -> ManualConsentFormNoticeView {
        return ManualConsentFormNoticeView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            attempts: String(item.attempts),
            regionText: item.region,
            startsAt: String(item.startsAt),
            wardText: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualConsentFormNoticeViews(_ items: [ManualConsentFormNotice]) -> [ManualConsentFormNoticeView] {
        var views: [ManualConsentFormNoticeView] = []
        for item in items {
            views.append(toManualConsentFormNoticeView(item))
        }
        return views
    }

    static func sumManualConsentFormNoticeView(_ view: ManualConsentFormNoticeView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedStartsAt)
    }
}
