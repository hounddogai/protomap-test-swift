import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient inventory override.
    final class LenientInventoryOverrideView {
        var code: String
        var label: String
        var margin: String
        var regionText: String
        var updatedAt: String
        var contactEmail: String
        var nameText: String
        var graceDays: String
        var phone: String
        var rate: String
        var discountText: String
        var statusLabel: String

        init(code: String, label: String, margin: String, regionText: String, updatedAt: String, contactEmail: String, nameText: String, graceDays: String, phone: String, rate: String, discountText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.margin = margin
            self.regionText = regionText
            self.updatedAt = updatedAt
            self.contactEmail = contactEmail
            self.nameText = nameText
            self.graceDays = graceDays
            self.phone = phone
            self.rate = rate
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientInventoryOverrideView(_ item: LenientInventoryOverride) -> LenientInventoryOverrideView {
        return LenientInventoryOverrideView(
            code: item.code,
            label: item.label,
            margin: String(format: "%.2f", item.margin),
            regionText: Kit.Text.truncate(item.region, limit: 40),
            updatedAt: String(item.updatedAt),
            contactEmail: item.contactEmail,
            nameText: item.name,
            graceDays: String(item.graceDays),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            rate: String(format: "%.2f", item.rate),
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientInventoryOverrideViews(_ items: [LenientInventoryOverride]) -> [LenientInventoryOverrideView] {
        var views: [LenientInventoryOverrideView] = []
        for item in items {
            views.append(toLenientInventoryOverrideView(item))
        }
        return views
    }

    static func sumLenientInventoryOverrideView(_ view: LenientInventoryOverrideView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMargin + Double(parsedUpdatedAt) + Double(parsedGraceDays)
    }
}
