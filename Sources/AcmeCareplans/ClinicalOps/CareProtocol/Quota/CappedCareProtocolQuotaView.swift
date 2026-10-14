import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a capped care protocol quota.
    final class CappedCareProtocolQuotaView {
        var codeText: String
        var label: String
        var contactEmailText: String
        var discountText: String
        var procedureCode: String
        var updatedAtText: String
        var statusLabel: String

        init(codeText: String, label: String, contactEmailText: String, discountText: String, procedureCode: String, updatedAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.contactEmailText = contactEmailText
            self.discountText = discountText
            self.procedureCode = procedureCode
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCareProtocolQuotaView(_ item: CappedCareProtocolQuota) -> CappedCareProtocolQuotaView {
        return CappedCareProtocolQuotaView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 120),
            contactEmailText: item.contactEmail,
            discountText: String(format: "%.2f", item.discount),
            procedureCode: item.procedureCode,
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCareProtocolQuotaViews(_ items: [CappedCareProtocolQuota]) -> [CappedCareProtocolQuotaView] {
        var views: [CappedCareProtocolQuotaView] = []
        for item in items {
            views.append(toCappedCareProtocolQuotaView(item))
        }
        return views
    }

    static func sumCappedCareProtocolQuotaView(_ view: CappedCareProtocolQuotaView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedDiscount + Double(parsedUpdatedAt)
    }
}
