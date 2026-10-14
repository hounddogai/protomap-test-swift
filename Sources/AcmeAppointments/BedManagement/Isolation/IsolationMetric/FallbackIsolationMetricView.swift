import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback isolation metric.
    final class FallbackIsolationMetricView {
        var code: String
        var titleText: String
        var payer: String
        var contactEmail: String
        var allergy: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, payer: String, contactEmail: String, allergy: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.payer = payer
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackIsolationMetricView(_ item: FallbackIsolationMetric) -> FallbackIsolationMetricView {
        return FallbackIsolationMetricView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            payer: item.payer,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            allergy: item.allergy,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackIsolationMetricViews(_ items: [FallbackIsolationMetric]) -> [FallbackIsolationMetricView] {
        var views: [FallbackIsolationMetricView] = []
        for item in items {
            views.append(toFallbackIsolationMetricView(item))
        }
        return views
    }

    static func sumFallbackIsolationMetricView(_ view: FallbackIsolationMetricView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
