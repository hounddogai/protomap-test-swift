import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted order set exception.
    final class WeightedOrderSetExceptionView {
        var code: String
        var label: String
        var margin: String
        var unit: String
        var graceDays: String
        var reviewer: String
        var statusLabel: String

        init(code: String, label: String, margin: String, unit: String, graceDays: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.margin = margin
            self.unit = unit
            self.graceDays = graceDays
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedOrderSetExceptionView(_ item: WeightedOrderSetException) -> WeightedOrderSetExceptionView {
        return WeightedOrderSetExceptionView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            margin: String(format: "%.2f", item.margin),
            unit: item.unit,
            graceDays: String(item.graceDays),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedOrderSetExceptionViews(_ items: [WeightedOrderSetException]) -> [WeightedOrderSetExceptionView] {
        var views: [WeightedOrderSetExceptionView] = []
        for item in items {
            views.append(toWeightedOrderSetExceptionView(item))
        }
        return views
    }

    static func sumWeightedOrderSetExceptionView(_ view: WeightedOrderSetExceptionView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMargin + Double(parsedGraceDays)
    }
}
