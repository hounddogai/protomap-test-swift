import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive transfer metric.
    final class AdaptiveTransferMetricView {
        var codeText: String
        var title: String
        var discount: String
        var startsAt: String
        var attempts: String
        var retriesText: String
        var timezone: String
        var sequenceText: String
        var costText: String
        var segment: String
        var statusLabel: String

        init(codeText: String, title: String, discount: String, startsAt: String, attempts: String, retriesText: String, timezone: String, sequenceText: String, costText: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.discount = discount
            self.startsAt = startsAt
            self.attempts = attempts
            self.retriesText = retriesText
            self.timezone = timezone
            self.sequenceText = sequenceText
            self.costText = costText
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveTransferMetricView(_ item: AdaptiveTransferMetric) -> AdaptiveTransferMetricView {
        return AdaptiveTransferMetricView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 120),
            discount: String(format: "%.2f", item.discount),
            startsAt: String(item.startsAt),
            attempts: String(item.attempts),
            retriesText: String(item.retries),
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            sequenceText: String(item.sequence),
            costText: String(format: "%.2f", item.cost),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveTransferMetricViews(_ items: [AdaptiveTransferMetric]) -> [AdaptiveTransferMetricView] {
        var views: [AdaptiveTransferMetricView] = []
        for item in items {
            views.append(toAdaptiveTransferMetricView(item))
        }
        return views
    }

    static func sumAdaptiveTransferMetricView(_ view: AdaptiveTransferMetricView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedDiscount + Double(parsedStartsAt) + Double(parsedAttempts)
    }
}
