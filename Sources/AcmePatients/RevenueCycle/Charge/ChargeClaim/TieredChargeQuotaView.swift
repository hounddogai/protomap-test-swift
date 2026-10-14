import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered charge quota.
    final class TieredChargeQuotaView {
        var codeText: String
        var label: String
        var procedureCode: String
        var contactEmailText: String
        var rate: String
        var discount: String
        var ceiling: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, label: String, procedureCode: String, contactEmailText: String, rate: String, discount: String, ceiling: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.procedureCode = procedureCode
            self.contactEmailText = contactEmailText
            self.rate = rate
            self.discount = discount
            self.ceiling = ceiling
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredChargeQuotaView(_ item: TieredChargeQuota) -> TieredChargeQuotaView {
        return TieredChargeQuotaView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            procedureCode: item.procedureCode,
            contactEmailText: item.contactEmail,
            rate: String(format: "%.2f", item.rate),
            discount: String(format: "%.2f", item.discount),
            ceiling: String(format: "%.2f", item.ceiling),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredChargeQuotaViews(_ items: [TieredChargeQuota]) -> [TieredChargeQuotaView] {
        var views: [TieredChargeQuotaView] = []
        for item in items {
            views.append(toTieredChargeQuotaView(item))
        }
        return views
    }

    static func sumTieredChargeQuotaView(_ view: TieredChargeQuotaView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedRate + parsedDiscount + parsedCeiling
    }
}
