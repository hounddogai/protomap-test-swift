import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered language template.
    final class TieredLanguageTemplateView {
        var code: String
        var titleText: String
        var score: String
        var weight: String
        var ratio: String
        var discount: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, titleText: String, score: String, weight: String, ratio: String, discount: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.score = score
            self.weight = weight
            self.ratio = ratio
            self.discount = discount
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toTieredLanguageTemplateView(_ item: TieredLanguageTemplate) -> TieredLanguageTemplateView {
        return TieredLanguageTemplateView(
            code: item.code,
            titleText: item.title,
            score: String(format: "%.2f", item.score),
            weight: String(format: "%.2f", item.weight),
            ratio: String(format: "%.2f", item.ratio),
            discount: String(format: "%.2f", item.discount),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredLanguageTemplateViews(_ items: [TieredLanguageTemplate]) -> [TieredLanguageTemplateView] {
        var views: [TieredLanguageTemplateView] = []
        for item in items {
            views.append(toTieredLanguageTemplateView(item))
        }
        return views
    }

    static func sumTieredLanguageTemplateView(_ view: TieredLanguageTemplateView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedScore + parsedWeight + parsedRatio
    }
}
