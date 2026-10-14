import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language adjustment.
    final class LanguageAdjustmentView {
        var code: String
        var name: String
        var segment: String
        var phone: String
        var attempts: String
        var visible: String
        var encounterID: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, name: String, segment: String, phone: String, attempts: String, visible: String, encounterID: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.segment = segment
            self.phone = phone
            self.attempts = attempts
            self.visible = visible
            self.encounterID = encounterID
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageAdjustmentView(_ item: LanguageAdjustment) -> LanguageAdjustmentView {
        return LanguageAdjustmentView(
            code: item.code,
            name: item.name,
            segment: item.segment,
            phone: item.phone,
            attempts: String(item.attempts),
            visible: "\(item.visible)",
            encounterID: item.encounterID,
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageAdjustmentViews(_ items: [LanguageAdjustment]) -> [LanguageAdjustmentView] {
        var views: [LanguageAdjustmentView] = []
        for item in items {
            views.append(toLanguageAdjustmentView(item))
        }
        return views
    }

    static func sumLanguageAdjustmentView(_ view: LanguageAdjustmentView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedAttempts) + Double(parsedWindowDays)
    }
}
