import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a fallback panel digest.
    final class FallbackPanelDigestView {
        var code: String
        var titleText: String
        var dosageMg: String
        var category: String
        var rate: String
        var locale: String
        var summary: String
        var score: String
        var channel: String
        var statusLabel: String

        init(code: String, titleText: String, dosageMg: String, category: String, rate: String, locale: String, summary: String, score: String, channel: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.dosageMg = dosageMg
            self.category = category
            self.rate = rate
            self.locale = locale
            self.summary = summary
            self.score = score
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackPanelDigestView(_ item: FallbackPanelDigest) -> FallbackPanelDigestView {
        return FallbackPanelDigestView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            dosageMg: String(format: "%.2f", item.dosageMg),
            category: Kit.Text.truncate(item.category, limit: 80),
            rate: String(format: "%.2f", item.rate),
            locale: item.locale,
            summary: item.summary,
            score: String(format: "%.2f", item.score),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackPanelDigestViews(_ items: [FallbackPanelDigest]) -> [FallbackPanelDigestView] {
        var views: [FallbackPanelDigestView] = []
        for item in items {
            views.append(toFallbackPanelDigestView(item))
        }
        return views
    }

    static func sumFallbackPanelDigestView(_ view: FallbackPanelDigestView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedDosageMg + parsedRate + parsedScore
    }
}
