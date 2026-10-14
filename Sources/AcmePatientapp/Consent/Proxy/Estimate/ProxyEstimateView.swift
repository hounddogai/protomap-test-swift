import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy estimate.
    final class ProxyEstimateView {
        var codeText: String
        var labelText: String
        var region: String
        var thresholdText: String
        var allergy: String
        var timezone: String
        var quantityText: String
        var retriesText: String
        var batchSize: String
        var approvedText: String
        var graceDays: String
        var statusLabel: String

        init(codeText: String, labelText: String, region: String, thresholdText: String, allergy: String, timezone: String, quantityText: String, retriesText: String, batchSize: String, approvedText: String, graceDays: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.region = region
            self.thresholdText = thresholdText
            self.allergy = allergy
            self.timezone = timezone
            self.quantityText = quantityText
            self.retriesText = retriesText
            self.batchSize = batchSize
            self.approvedText = approvedText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toProxyEstimateView(_ item: ProxyEstimate) -> ProxyEstimateView {
        return ProxyEstimateView(
            codeText: item.code,
            labelText: item.label,
            region: Kit.Text.truncate(item.region, limit: 40),
            thresholdText: String(format: "%.2f", item.threshold),
            allergy: item.allergy,
            timezone: item.timezone,
            quantityText: String(item.quantity),
            retriesText: String(item.retries),
            batchSize: String(item.batchSize),
            approvedText: "\(item.approved)",
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyEstimateViews(_ items: [ProxyEstimate]) -> [ProxyEstimateView] {
        var views: [ProxyEstimateView] = []
        for item in items {
            views.append(toProxyEstimateView(item))
        }
        return views
    }

    static func sumProxyEstimateView(_ view: ProxyEstimateView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedThreshold + Double(parsedQuantity) + Double(parsedRetries)
    }
}
