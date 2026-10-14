import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive remittance quota.
    final class AdaptiveRemittanceQuotaView {
        var code: String
        var label: String
        var segment: String
        var revision: String
        var maximum: String
        var startsAtText: String
        var amount: String
        var weightText: String
        var ratio: String
        var ward: String
        var categoryText: String
        var statusLabel: String

        init(code: String, label: String, segment: String, revision: String, maximum: String, startsAtText: String, amount: String, weightText: String, ratio: String, ward: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segment = segment
            self.revision = revision
            self.maximum = maximum
            self.startsAtText = startsAtText
            self.amount = amount
            self.weightText = weightText
            self.ratio = ratio
            self.ward = ward
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRemittanceQuotaView(_ item: AdaptiveRemittanceQuota) -> AdaptiveRemittanceQuotaView {
        return AdaptiveRemittanceQuotaView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 40),
            segment: Kit.Text.truncate(item.segment, limit: 80),
            revision: String(item.revision),
            maximum: String(format: "%.2f", item.maximum),
            startsAtText: String(item.startsAt),
            amount: String(format: "%.2f", item.amount),
            weightText: String(format: "%.2f", item.weight),
            ratio: String(format: "%.2f", item.ratio),
            ward: item.ward,
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRemittanceQuotaViews(_ items: [AdaptiveRemittanceQuota]) -> [AdaptiveRemittanceQuotaView] {
        var views: [AdaptiveRemittanceQuotaView] = []
        for item in items {
            views.append(toAdaptiveRemittanceQuotaView(item))
        }
        return views
    }

    static func sumAdaptiveRemittanceQuotaView(_ view: AdaptiveRemittanceQuotaView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedRevision) + parsedMaximum + Double(parsedStartsAt)
    }
}
