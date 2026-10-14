import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive worklist draft.
    final class AdaptiveWorklistDraftView {
        var code: String
        var nameText: String
        var payer: String
        var currencyText: String
        var segmentText: String
        var scoreText: String
        var statusLabel: String

        init(code: String, nameText: String, payer: String, currencyText: String, segmentText: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payer = payer
            self.currencyText = currencyText
            self.segmentText = segmentText
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveWorklistDraftView(_ item: AdaptiveWorklistDraft) -> AdaptiveWorklistDraftView {
        return AdaptiveWorklistDraftView(
            code: item.code,
            nameText: item.name,
            payer: item.payer,
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            segmentText: item.segment,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveWorklistDraftViews(_ items: [AdaptiveWorklistDraft]) -> [AdaptiveWorklistDraftView] {
        var views: [AdaptiveWorklistDraftView] = []
        for item in items {
            views.append(toAdaptiveWorklistDraftView(item))
        }
        return views
    }

    static func sumAdaptiveWorklistDraftView(_ view: AdaptiveWorklistDraftView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
