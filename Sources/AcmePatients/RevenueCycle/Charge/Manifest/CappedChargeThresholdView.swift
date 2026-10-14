import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped charge threshold.
    final class CappedChargeThresholdView {
        var code: String
        var titleText: String
        var category: String
        var maximum: String
        var visibleText: String
        var country: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, titleText: String, category: String, maximum: String, visibleText: String, country: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.category = category
            self.maximum = maximum
            self.visibleText = visibleText
            self.country = country
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedChargeThresholdView(_ item: CappedChargeThreshold) -> CappedChargeThresholdView {
        return CappedChargeThresholdView(
            code: Kit.Text.truncate(item.code, limit: 80),
            titleText: item.title,
            category: item.category,
            maximum: String(format: "%.2f", item.maximum),
            visibleText: "\(item.visible)",
            country: item.country,
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedChargeThresholdViews(_ items: [CappedChargeThreshold]) -> [CappedChargeThresholdView] {
        var views: [CappedChargeThresholdView] = []
        for item in items {
            views.append(toCappedChargeThresholdView(item))
        }
        return views
    }

    static func sumCappedChargeThresholdView(_ view: CappedChargeThresholdView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMaximum + Double(parsedUpdatedAt)
    }
}
