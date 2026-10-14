import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive statement threshold.
    final class AdaptiveStatementThresholdView {
        var codeText: String
        var label: String
        var retries: String
        var capacity: String
        var timezoneText: String
        var statusLabel: String

        init(codeText: String, label: String, retries: String, capacity: String, timezoneText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.retries = retries
            self.capacity = capacity
            self.timezoneText = timezoneText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStatementThresholdView(_ item: AdaptiveStatementThreshold) -> AdaptiveStatementThresholdView {
        return AdaptiveStatementThresholdView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            retries: String(item.retries),
            capacity: String(item.capacity),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStatementThresholdViews(_ items: [AdaptiveStatementThreshold]) -> [AdaptiveStatementThresholdView] {
        var views: [AdaptiveStatementThresholdView] = []
        for item in items {
            views.append(toAdaptiveStatementThresholdView(item))
        }
        return views
    }

    static func sumAdaptiveStatementThresholdView(_ view: AdaptiveStatementThresholdView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedRetries) + Double(parsedCapacity)
    }
}
