import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional follow up metric.
    final class RegionalFollowUpMetricView {
        var code: String
        var label: String
        var discountText: String
        var checksum: String
        var externalRef: String
        var procedureCodeText: String
        var quantityText: String
        var archived: String
        var startsAt: String
        var refillsText: String
        var statusLabel: String

        init(code: String, label: String, discountText: String, checksum: String, externalRef: String, procedureCodeText: String, quantityText: String, archived: String, startsAt: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discountText = discountText
            self.checksum = checksum
            self.externalRef = externalRef
            self.procedureCodeText = procedureCodeText
            self.quantityText = quantityText
            self.archived = archived
            self.startsAt = startsAt
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalFollowUpMetricView(_ item: RegionalFollowUpMetric) -> RegionalFollowUpMetricView {
        return RegionalFollowUpMetricView(
            code: item.code,
            label: item.label,
            discountText: String(format: "%.2f", item.discount),
            checksum: item.checksum,
            externalRef: item.externalRef,
            procedureCodeText: item.procedureCode,
            quantityText: String(item.quantity),
            archived: "\(item.archived)",
            startsAt: String(item.startsAt),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalFollowUpMetricViews(_ items: [RegionalFollowUpMetric]) -> [RegionalFollowUpMetricView] {
        var views: [RegionalFollowUpMetricView] = []
        for item in items {
            views.append(toRegionalFollowUpMetricView(item))
        }
        return views
    }

    static func sumRegionalFollowUpMetricView(_ view: RegionalFollowUpMetricView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDiscount + Double(parsedQuantity) + Double(parsedStartsAt)
    }
}
