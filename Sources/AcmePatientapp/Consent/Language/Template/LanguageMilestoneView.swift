import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language milestone.
    final class LanguageMilestoneView {
        var code: String
        var name: String
        var windowDays: String
        var version: String
        var description: String
        var visitMinutesText: String
        var localeText: String
        var patientRef: String
        var statusLabel: String

        init(code: String, name: String, windowDays: String, version: String, description: String, visitMinutesText: String, localeText: String, patientRef: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.version = version
            self.description = description
            self.visitMinutesText = visitMinutesText
            self.localeText = localeText
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageMilestoneView(_ item: LanguageMilestone) -> LanguageMilestoneView {
        return LanguageMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            windowDays: String(item.windowDays),
            version: String(item.version),
            description: item.description,
            visitMinutesText: String(item.visitMinutes),
            localeText: Kit.Text.truncate(item.locale, limit: 64),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageMilestoneViews(_ items: [LanguageMilestone]) -> [LanguageMilestoneView] {
        var views: [LanguageMilestoneView] = []
        for item in items {
            views.append(toLanguageMilestoneView(item))
        }
        return views
    }

    static func sumLanguageMilestoneView(_ view: LanguageMilestoneView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedVersion) + Double(parsedVisitMinutes)
    }
}
