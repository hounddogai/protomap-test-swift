import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default disclosure summary.
    final class DefaultDisclosureSummaryView {
        var code: String
        var nameText: String
        var externalRef: String
        var minimum: String
        var encounterID: String
        var procedureCode: String
        var allergyText: String
        var timezoneText: String
        var locale: String
        var createdAt: String
        var startsAt: String
        var statusLabel: String

        init(code: String, nameText: String, externalRef: String, minimum: String, encounterID: String, procedureCode: String, allergyText: String, timezoneText: String, locale: String, createdAt: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.externalRef = externalRef
            self.minimum = minimum
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.allergyText = allergyText
            self.timezoneText = timezoneText
            self.locale = locale
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultDisclosureSummaryView(_ item: DefaultDisclosureSummary) -> DefaultDisclosureSummaryView {
        return DefaultDisclosureSummaryView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            externalRef: item.externalRef,
            minimum: String(format: "%.2f", item.minimum),
            encounterID: item.encounterID,
            procedureCode: item.procedureCode,
            allergyText: item.allergy,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 120),
            locale: Kit.Text.truncate(item.locale, limit: 40),
            createdAt: String(item.createdAt),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultDisclosureSummaryViews(_ items: [DefaultDisclosureSummary]) -> [DefaultDisclosureSummaryView] {
        var views: [DefaultDisclosureSummaryView] = []
        for item in items {
            views.append(toDefaultDisclosureSummaryView(item))
        }
        return views
    }

    static func sumDefaultDisclosureSummaryView(_ view: DefaultDisclosureSummaryView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedMinimum + Double(parsedCreatedAt) + Double(parsedStartsAt)
    }
}
