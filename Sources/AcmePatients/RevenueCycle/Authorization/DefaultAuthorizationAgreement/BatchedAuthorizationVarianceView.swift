import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched authorization variance.
    final class BatchedAuthorizationVarianceView {
        var code: String
        var label: String
        var encounterID: String
        var currencyText: String
        var summaryText: String
        var timezone: String
        var margin: String
        var threshold: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, currencyText: String, summaryText: String, timezone: String, margin: String, threshold: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.currencyText = currencyText
            self.summaryText = summaryText
            self.timezone = timezone
            self.margin = margin
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedAuthorizationVarianceView(_ item: BatchedAuthorizationVariance) -> BatchedAuthorizationVarianceView {
        return BatchedAuthorizationVarianceView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            currencyText: item.currency,
            summaryText: item.summary,
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            margin: String(format: "%.2f", item.margin),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedAuthorizationVarianceViews(_ items: [BatchedAuthorizationVariance]) -> [BatchedAuthorizationVarianceView] {
        var views: [BatchedAuthorizationVarianceView] = []
        for item in items {
            views.append(toBatchedAuthorizationVarianceView(item))
        }
        return views
    }

    static func sumBatchedAuthorizationVarianceView(_ view: BatchedAuthorizationVarianceView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedMargin + parsedThreshold
    }
}
