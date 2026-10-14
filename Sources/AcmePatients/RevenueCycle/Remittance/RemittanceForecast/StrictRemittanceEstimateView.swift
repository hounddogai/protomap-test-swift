import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a strict remittance estimate.
    final class StrictRemittanceEstimateView {
        var code: String
        var name: String
        var source: String
        var rate: String
        var maximum: String
        var statusLabel: String

        init(code: String, name: String, source: String, rate: String, maximum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.source = source
            self.rate = rate
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toStrictRemittanceEstimateView(_ item: StrictRemittanceEstimate) -> StrictRemittanceEstimateView {
        return StrictRemittanceEstimateView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            source: item.source,
            rate: String(format: "%.2f", item.rate),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictRemittanceEstimateViews(_ items: [StrictRemittanceEstimate]) -> [StrictRemittanceEstimateView] {
        var views: [StrictRemittanceEstimateView] = []
        for item in items {
            views.append(toStrictRemittanceEstimateView(item))
        }
        return views
    }

    static func sumStrictRemittanceEstimateView(_ view: StrictRemittanceEstimateView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedRate + parsedMaximum
    }
}
