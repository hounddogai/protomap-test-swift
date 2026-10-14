import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a seasonal charge score.
    final class SeasonalChargeScoreView {
        var code: String
        var name: String
        var category: String
        var currency: String
        var scoreText: String
        var limit: String
        var graceDays: String
        var visitMinutes: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, name: String, category: String, currency: String, scoreText: String, limit: String, graceDays: String, visitMinutes: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.category = category
            self.currency = currency
            self.scoreText = scoreText
            self.limit = limit
            self.graceDays = graceDays
            self.visitMinutes = visitMinutes
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalChargeScoreView(_ item: SeasonalChargeScore) -> SeasonalChargeScoreView {
        return SeasonalChargeScoreView(
            code: item.code,
            name: item.name,
            category: Kit.Text.truncate(item.category, limit: 120),
            currency: item.currency,
            scoreText: String(format: "%.2f", item.score),
            limit: String(item.limit),
            graceDays: String(item.graceDays),
            visitMinutes: String(item.visitMinutes),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalChargeScoreViews(_ items: [SeasonalChargeScore]) -> [SeasonalChargeScoreView] {
        var views: [SeasonalChargeScoreView] = []
        for item in items {
            views.append(toSeasonalChargeScoreView(item))
        }
        return views
    }

    static func sumSeasonalChargeScoreView(_ view: SeasonalChargeScoreView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedScore + Double(parsedLimit) + Double(parsedGraceDays)
    }
}
