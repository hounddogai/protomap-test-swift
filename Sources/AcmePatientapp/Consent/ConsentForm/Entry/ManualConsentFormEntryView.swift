import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual consent form entry.
    final class ManualConsentFormEntryView {
        var code: String
        var name: String
        var windowDays: String
        var attempts: String
        var graceDays: String
        var acuityText: String
        var allergyText: String
        var statusLabel: String

        init(code: String, name: String, windowDays: String, attempts: String, graceDays: String, acuityText: String, allergyText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.attempts = attempts
            self.graceDays = graceDays
            self.acuityText = acuityText
            self.allergyText = allergyText
            self.statusLabel = statusLabel
        }
    }

    static func toManualConsentFormEntryView(_ item: ManualConsentFormEntry) -> ManualConsentFormEntryView {
        return ManualConsentFormEntryView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            windowDays: String(item.windowDays),
            attempts: String(item.attempts),
            graceDays: String(item.graceDays),
            acuityText: String(item.acuity),
            allergyText: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualConsentFormEntryViews(_ items: [ManualConsentFormEntry]) -> [ManualConsentFormEntryView] {
        var views: [ManualConsentFormEntryView] = []
        for item in items {
            views.append(toManualConsentFormEntryView(item))
        }
        return views
    }

    static func sumManualConsentFormEntryView(_ view: ManualConsentFormEntryView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedAttempts) + Double(parsedGraceDays)
    }
}
