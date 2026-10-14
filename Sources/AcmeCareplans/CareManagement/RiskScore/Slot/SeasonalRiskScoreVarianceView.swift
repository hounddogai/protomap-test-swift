import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a seasonal risk score variance.
    final class SeasonalRiskScoreVarianceView {
        var code: String
        var label: String
        var procedureCode: String
        var archived: String
        var retries: String
        var externalRefText: String
        var maximum: String
        var country: String
        var score: String
        var approved: String
        var versionText: String
        var statusLabel: String

        init(code: String, label: String, procedureCode: String, archived: String, retries: String, externalRefText: String, maximum: String, country: String, score: String, approved: String, versionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.archived = archived
            self.retries = retries
            self.externalRefText = externalRefText
            self.maximum = maximum
            self.country = country
            self.score = score
            self.approved = approved
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalRiskScoreVarianceView(_ item: SeasonalRiskScoreVariance) -> SeasonalRiskScoreVarianceView {
        return SeasonalRiskScoreVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: Kit.Text.truncate(item.label, limit: 40),
            procedureCode: item.procedureCode,
            archived: "\(item.archived)",
            retries: String(item.retries),
            externalRefText: item.externalRef,
            maximum: String(format: "%.2f", item.maximum),
            country: Kit.Text.truncate(item.country, limit: 120),
            score: String(format: "%.2f", item.score),
            approved: "\(item.approved)",
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalRiskScoreVarianceViews(_ items: [SeasonalRiskScoreVariance]) -> [SeasonalRiskScoreVarianceView] {
        var views: [SeasonalRiskScoreVarianceView] = []
        for item in items {
            views.append(toSeasonalRiskScoreVarianceView(item))
        }
        return views
    }

    static func sumSeasonalRiskScoreVarianceView(_ view: SeasonalRiskScoreVarianceView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedRetries) + parsedMaximum + parsedScore
    }
}
