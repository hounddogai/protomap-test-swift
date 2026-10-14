import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall score.
    final class RecallScoreView {
        var code: String
        var label: String
        var currencyText: String
        var ratioText: String
        var payer: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, currencyText: String, ratioText: String, payer: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.currencyText = currencyText
            self.ratioText = ratioText
            self.payer = payer
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toRecallScoreView(_ item: RecallScore) -> RecallScoreView {
        return RecallScoreView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 80),
            currencyText: item.currency,
            ratioText: String(format: "%.2f", item.ratio),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallScoreViews(_ items: [RecallScore]) -> [RecallScoreView] {
        var views: [RecallScoreView] = []
        for item in items {
            views.append(toRecallScoreView(item))
        }
        return views
    }

    static func sumRecallScoreView(_ view: RecallScoreView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
