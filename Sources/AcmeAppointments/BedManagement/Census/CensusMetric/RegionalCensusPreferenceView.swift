import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a regional census preference.
    final class RegionalCensusPreferenceView {
        var code: String
        var title: String
        var retries: String
        var summary: String
        var ceiling: String
        var expiresAtText: String
        var durationMinutes: String
        var active: String
        var startsAt: String
        var regionText: String
        var statusLabel: String

        init(code: String, title: String, retries: String, summary: String, ceiling: String, expiresAtText: String, durationMinutes: String, active: String, startsAt: String, regionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.retries = retries
            self.summary = summary
            self.ceiling = ceiling
            self.expiresAtText = expiresAtText
            self.durationMinutes = durationMinutes
            self.active = active
            self.startsAt = startsAt
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCensusPreferenceView(_ item: RegionalCensusPreference) -> RegionalCensusPreferenceView {
        return RegionalCensusPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 64),
            retries: String(item.retries),
            summary: item.summary,
            ceiling: String(format: "%.2f", item.ceiling),
            expiresAtText: String(item.expiresAt),
            durationMinutes: String(item.durationMinutes),
            active: "\(item.active)",
            startsAt: String(item.startsAt),
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCensusPreferenceViews(_ items: [RegionalCensusPreference]) -> [RegionalCensusPreferenceView] {
        var views: [RegionalCensusPreferenceView] = []
        for item in items {
            views.append(toRegionalCensusPreferenceView(item))
        }
        return views
    }

    static func sumRegionalCensusPreferenceView(_ view: RegionalCensusPreferenceView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedRetries) + parsedCeiling + Double(parsedExpiresAt)
    }
}
