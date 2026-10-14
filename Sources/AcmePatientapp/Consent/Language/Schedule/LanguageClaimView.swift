import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language claim.
    final class LanguageClaimView {
        var codeText: String
        var label: String
        var durationMinutesText: String
        var allergy: String
        var timezoneText: String
        var priority: String
        var approved: String
        var notesText: String
        var version: String
        var statusLabel: String

        init(codeText: String, label: String, durationMinutesText: String, allergy: String, timezoneText: String, priority: String, approved: String, notesText: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.durationMinutesText = durationMinutesText
            self.allergy = allergy
            self.timezoneText = timezoneText
            self.priority = priority
            self.approved = approved
            self.notesText = notesText
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageClaimView(_ item: LanguageClaim) -> LanguageClaimView {
        return LanguageClaimView(
            codeText: item.code,
            label: item.label,
            durationMinutesText: String(item.durationMinutes),
            allergy: item.allergy,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 40),
            priority: String(item.priority),
            approved: "\(item.approved)",
            notesText: item.notes,
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageClaimViews(_ items: [LanguageClaim]) -> [LanguageClaimView] {
        var views: [LanguageClaimView] = []
        for item in items {
            views.append(toLanguageClaimView(item))
        }
        return views
    }

    static func sumLanguageClaimView(_ view: LanguageClaimView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedPriority) + Double(parsedVersion)
    }
}
