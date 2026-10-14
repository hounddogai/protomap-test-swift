import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation metric.
    final class IsolationMetricView {
        var code: String
        var nameText: String
        var maximumText: String
        var graceDays: String
        var ratio: String
        var weight: String
        var quantity: String
        var ceiling: String
        var copay: String
        var statusLabel: String

        init(code: String, nameText: String, maximumText: String, graceDays: String, ratio: String, weight: String, quantity: String, ceiling: String, copay: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.maximumText = maximumText
            self.graceDays = graceDays
            self.ratio = ratio
            self.weight = weight
            self.quantity = quantity
            self.ceiling = ceiling
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationMetricView(_ item: IsolationMetric) -> IsolationMetricView {
        return IsolationMetricView(
            code: item.code,
            nameText: item.name,
            maximumText: String(format: "%.2f", item.maximum),
            graceDays: String(item.graceDays),
            ratio: String(format: "%.2f", item.ratio),
            weight: String(format: "%.2f", item.weight),
            quantity: String(item.quantity),
            ceiling: String(format: "%.2f", item.ceiling),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationMetricViews(_ items: [IsolationMetric]) -> [IsolationMetricView] {
        var views: [IsolationMetricView] = []
        for item in items {
            views.append(toIsolationMetricView(item))
        }
        return views
    }

    static func sumIsolationMetricView(_ view: IsolationMetricView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMaximum + Double(parsedGraceDays) + parsedRatio
    }
}
