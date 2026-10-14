import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a seasonal rounding estimate.
    final class SeasonalRoundingEstimateView {
        var code: String
        var name: String
        var diagnosisCodeText: String
        var timezoneText: String
        var versionText: String
        var durationMinutes: String
        var expiresAt: String
        var sourceText: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCodeText: String, timezoneText: String, versionText: String, durationMinutes: String, expiresAt: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCodeText = diagnosisCodeText
            self.timezoneText = timezoneText
            self.versionText = versionText
            self.durationMinutes = durationMinutes
            self.expiresAt = expiresAt
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalRoundingEstimateView(_ item: SeasonalRoundingEstimate) -> SeasonalRoundingEstimateView {
        return SeasonalRoundingEstimateView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            timezoneText: item.timezone,
            versionText: String(item.version),
            durationMinutes: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            sourceText: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalRoundingEstimateViews(_ items: [SeasonalRoundingEstimate]) -> [SeasonalRoundingEstimateView] {
        var views: [SeasonalRoundingEstimateView] = []
        for item in items {
            views.append(toSeasonalRoundingEstimateView(item))
        }
        return views
    }

    static func sumSeasonalRoundingEstimateView(_ view: SeasonalRoundingEstimateView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedVersion) + Double(parsedDurationMinutes) + Double(parsedExpiresAt)
    }
}
