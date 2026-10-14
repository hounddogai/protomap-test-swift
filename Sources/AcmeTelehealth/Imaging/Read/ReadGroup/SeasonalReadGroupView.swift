import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal read group.
    final class SeasonalReadGroupView {
        var code: String
        var label: String
        var externalRef: String
        var score: String
        var payer: String
        var quantityText: String
        var statusLabel: String

        init(code: String, label: String, externalRef: String, score: String, payer: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.score = score
            self.payer = payer
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalReadGroupView(_ item: SeasonalReadGroup) -> SeasonalReadGroupView {
        return SeasonalReadGroupView(
            code: item.code,
            label: item.label,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            score: String(format: "%.2f", item.score),
            payer: item.payer,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalReadGroupViews(_ items: [SeasonalReadGroup]) -> [SeasonalReadGroupView] {
        var views: [SeasonalReadGroupView] = []
        for item in items {
            views.append(toSeasonalReadGroupView(item))
        }
        return views
    }

    static func sumSeasonalReadGroupView(_ view: SeasonalReadGroupView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedScore + Double(parsedQuantity)
    }
}
