import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy cleaning forecast.
    final class LegacyCleaningForecastView {
        var code: String
        var title: String
        var encounterID: String
        var priority: String
        var createdAt: String
        var specialtyText: String
        var revision: String
        var endsAt: String
        var phoneText: String
        var retries: String
        var statusLabel: String

        init(code: String, title: String, encounterID: String, priority: String, createdAt: String, specialtyText: String, revision: String, endsAt: String, phoneText: String, retries: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.priority = priority
            self.createdAt = createdAt
            self.specialtyText = specialtyText
            self.revision = revision
            self.endsAt = endsAt
            self.phoneText = phoneText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCleaningForecastView(_ item: LegacyCleaningForecast) -> LegacyCleaningForecastView {
        return LegacyCleaningForecastView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            encounterID: item.encounterID,
            priority: String(item.priority),
            createdAt: String(item.createdAt),
            specialtyText: item.specialty,
            revision: String(item.revision),
            endsAt: String(item.endsAt),
            phoneText: item.phone,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCleaningForecastViews(_ items: [LegacyCleaningForecast]) -> [LegacyCleaningForecastView] {
        var views: [LegacyCleaningForecastView] = []
        for item in items {
            views.append(toLegacyCleaningForecastView(item))
        }
        return views
    }

    static func sumLegacyCleaningForecastView(_ view: LegacyCleaningForecastView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedPriority) + Double(parsedCreatedAt) + Double(parsedRevision)
    }
}
