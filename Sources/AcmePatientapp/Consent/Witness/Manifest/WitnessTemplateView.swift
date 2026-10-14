import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a witness template.
    final class WitnessTemplateView {
        var code: String
        var title: String
        var locale: String
        var externalRefText: String
        var category: String
        var scoreText: String
        var statusLabel: String

        init(code: String, title: String, locale: String, externalRefText: String, category: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.locale = locale
            self.externalRefText = externalRefText
            self.category = category
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toWitnessTemplateView(_ item: WitnessTemplate) -> WitnessTemplateView {
        return WitnessTemplateView(
            code: item.code,
            title: item.title,
            locale: item.locale,
            externalRefText: item.externalRef,
            category: item.category,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWitnessTemplateViews(_ items: [WitnessTemplate]) -> [WitnessTemplateView] {
        var views: [WitnessTemplateView] = []
        for item in items {
            views.append(toWitnessTemplateView(item))
        }
        return views
    }

    static func sumWitnessTemplateView(_ view: WitnessTemplateView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
