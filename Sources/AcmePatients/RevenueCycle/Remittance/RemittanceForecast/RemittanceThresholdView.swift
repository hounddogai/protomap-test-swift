import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance threshold.
    final class RemittanceThresholdView {
        var code: String
        var title: String
        var description: String
        var timezoneText: String
        var currencyText: String
        var discount: String
        var maximum: String
        var statusLabel: String

        init(code: String, title: String, description: String, timezoneText: String, currencyText: String, discount: String, maximum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.timezoneText = timezoneText
            self.currencyText = currencyText
            self.discount = discount
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceThresholdView(_ item: RemittanceThreshold) -> RemittanceThresholdView {
        return RemittanceThresholdView(
            code: item.code,
            title: item.title,
            description: Kit.Text.truncate(item.description, limit: 80),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 40),
            currencyText: item.currency,
            discount: String(format: "%.2f", item.discount),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceThresholdViews(_ items: [RemittanceThreshold]) -> [RemittanceThresholdView] {
        var views: [RemittanceThresholdView] = []
        for item in items {
            views.append(toRemittanceThresholdView(item))
        }
        return views
    }

    static func sumRemittanceThresholdView(_ view: RemittanceThresholdView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedDiscount + parsedMaximum
    }
}
