import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted float pool target.
    final class WeightedFloatPoolTargetView {
        var code: String
        var label: String
        var maximumText: String
        var source: String
        var quantity: String
        var statusLabel: String

        init(code: String, label: String, maximumText: String, source: String, quantity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.maximumText = maximumText
            self.source = source
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFloatPoolTargetView(_ item: WeightedFloatPoolTarget) -> WeightedFloatPoolTargetView {
        return WeightedFloatPoolTargetView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            maximumText: String(format: "%.2f", item.maximum),
            source: item.source,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFloatPoolTargetViews(_ items: [WeightedFloatPoolTarget]) -> [WeightedFloatPoolTargetView] {
        var views: [WeightedFloatPoolTargetView] = []
        for item in items {
            views.append(toWeightedFloatPoolTargetView(item))
        }
        return views
    }

    static func sumWeightedFloatPoolTargetView(_ view: WeightedFloatPoolTargetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedMaximum + Double(parsedQuantity)
    }
}
