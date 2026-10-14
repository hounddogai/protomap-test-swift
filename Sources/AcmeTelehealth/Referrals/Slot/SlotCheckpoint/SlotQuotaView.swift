import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot quota.
    final class SlotQuotaView {
        var code: String
        var titleText: String
        var category: String
        var encounterID: String
        var amount: String
        var discountText: String
        var allergy: String
        var contactEmailText: String
        var limit: String
        var statusLabel: String

        init(code: String, titleText: String, category: String, encounterID: String, amount: String, discountText: String, allergy: String, contactEmailText: String, limit: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.category = category
            self.encounterID = encounterID
            self.amount = amount
            self.discountText = discountText
            self.allergy = allergy
            self.contactEmailText = contactEmailText
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toSlotQuotaView(_ item: SlotQuota) -> SlotQuotaView {
        return SlotQuotaView(
            code: item.code,
            titleText: item.title,
            category: item.category,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            amount: String(format: "%.2f", item.amount),
            discountText: String(format: "%.2f", item.discount),
            allergy: item.allergy,
            contactEmailText: item.contactEmail,
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotQuotaViews(_ items: [SlotQuota]) -> [SlotQuotaView] {
        var views: [SlotQuotaView] = []
        for item in items {
            views.append(toSlotQuotaView(item))
        }
        return views
    }

    static func sumSlotQuotaView(_ view: SlotQuotaView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedAmount + parsedDiscount + Double(parsedLimit)
    }
}
