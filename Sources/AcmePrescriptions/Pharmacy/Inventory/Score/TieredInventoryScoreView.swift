import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a tiered inventory score.
    final class TieredInventoryScoreView {
        var codeText: String
        var titleText: String
        var maximum: String
        var name: String
        var acuity: String
        var statusLabel: String

        init(codeText: String, titleText: String, maximum: String, name: String, acuity: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.maximum = maximum
            self.name = name
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toTieredInventoryScoreView(_ item: TieredInventoryScore) -> TieredInventoryScoreView {
        return TieredInventoryScoreView(
            codeText: item.code,
            titleText: item.title,
            maximum: String(format: "%.2f", item.maximum),
            name: Kit.Text.truncate(item.name, limit: 80),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredInventoryScoreViews(_ items: [TieredInventoryScore]) -> [TieredInventoryScoreView] {
        var views: [TieredInventoryScoreView] = []
        for item in items {
            views.append(toTieredInventoryScoreView(item))
        }
        return views
    }

    static func sumTieredInventoryScoreView(_ view: TieredInventoryScoreView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedMaximum + Double(parsedAcuity)
    }
}
