import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling courier threshold.
    final class RollingCourierThresholdView {
        var codeText: String
        var title: String
        var payerText: String
        var region: String
        var maximum: String
        var rate: String
        var statusLabel: String

        init(codeText: String, title: String, payerText: String, region: String, maximum: String, rate: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.payerText = payerText
            self.region = region
            self.maximum = maximum
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCourierThresholdView(_ item: RollingCourierThreshold) -> RollingCourierThresholdView {
        return RollingCourierThresholdView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            payerText: item.payer,
            region: item.region,
            maximum: String(format: "%.2f", item.maximum),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCourierThresholdViews(_ items: [RollingCourierThreshold]) -> [RollingCourierThresholdView] {
        var views: [RollingCourierThresholdView] = []
        for item in items {
            views.append(toRollingCourierThresholdView(item))
        }
        return views
    }

    static func sumRollingCourierThresholdView(_ view: RollingCourierThresholdView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMaximum + parsedRate
    }
}
