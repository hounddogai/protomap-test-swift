import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding score.
    final class RoundingScoreView {
        var code: String
        var label: String
        var graceDaysText: String
        var region: String
        var minimum: String
        var discount: String
        var statusLabel: String

        init(code: String, label: String, graceDaysText: String, region: String, minimum: String, discount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.graceDaysText = graceDaysText
            self.region = region
            self.minimum = minimum
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingScoreView(_ item: RoundingScore) -> RoundingScoreView {
        return RoundingScoreView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            graceDaysText: String(item.graceDays),
            region: Kit.Text.truncate(item.region, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingScoreViews(_ items: [RoundingScore]) -> [RoundingScoreView] {
        var views: [RoundingScoreView] = []
        for item in items {
            views.append(toRoundingScoreView(item))
        }
        return views
    }

    static func sumRoundingScoreView(_ view: RoundingScoreView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedGraceDays) + parsedMinimum + parsedDiscount
    }
}
