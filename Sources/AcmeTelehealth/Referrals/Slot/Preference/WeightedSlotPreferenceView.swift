import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted slot preference.
    final class WeightedSlotPreferenceView {
        var code: String
        var title: String
        var patientRefText: String
        var locale: String
        var contactEmailText: String
        var summary: String
        var scoreText: String
        var statusLabel: String

        init(code: String, title: String, patientRefText: String, locale: String, contactEmailText: String, summary: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.patientRefText = patientRefText
            self.locale = locale
            self.contactEmailText = contactEmailText
            self.summary = summary
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSlotPreferenceView(_ item: WeightedSlotPreference) -> WeightedSlotPreferenceView {
        return WeightedSlotPreferenceView(
            code: item.code,
            title: item.title,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 120),
            locale: item.locale,
            contactEmailText: item.contactEmail,
            summary: Kit.Text.truncate(item.summary, limit: 64),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSlotPreferenceViews(_ items: [WeightedSlotPreference]) -> [WeightedSlotPreferenceView] {
        var views: [WeightedSlotPreferenceView] = []
        for item in items {
            views.append(toWeightedSlotPreferenceView(item))
        }
        return views
    }

    static func sumWeightedSlotPreferenceView(_ view: WeightedSlotPreferenceView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
