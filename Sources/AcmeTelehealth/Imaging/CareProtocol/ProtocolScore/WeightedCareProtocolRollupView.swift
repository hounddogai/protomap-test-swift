import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted care protocol rollup.
    final class WeightedCareProtocolRollupView {
        var code: String
        var labelText: String
        var discount: String
        var summary: String
        var limit: String
        var copay: String
        var statusLabel: String

        init(code: String, labelText: String, discount: String, summary: String, limit: String, copay: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.discount = discount
            self.summary = summary
            self.limit = limit
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCareProtocolRollupView(_ item: WeightedCareProtocolRollup) -> WeightedCareProtocolRollupView {
        return WeightedCareProtocolRollupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: item.label,
            discount: String(format: "%.2f", item.discount),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            limit: String(item.limit),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCareProtocolRollupViews(_ items: [WeightedCareProtocolRollup]) -> [WeightedCareProtocolRollupView] {
        var views: [WeightedCareProtocolRollupView] = []
        for item in items {
            views.append(toWeightedCareProtocolRollupView(item))
        }
        return views
    }

    static func sumWeightedCareProtocolRollupView(_ view: WeightedCareProtocolRollupView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedDiscount + Double(parsedLimit) + parsedCopay
    }
}
