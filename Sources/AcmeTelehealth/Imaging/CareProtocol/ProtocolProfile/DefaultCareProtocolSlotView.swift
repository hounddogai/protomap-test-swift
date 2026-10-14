import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a default care protocol slot.
    final class DefaultCareProtocolSlotView {
        var code: String
        var name: String
        var archived: String
        var discountText: String
        var currency: String
        var refills: String
        var contactEmailText: String
        var createdAt: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, archived: String, discountText: String, currency: String, refills: String, contactEmailText: String, createdAt: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.discountText = discountText
            self.currency = currency
            self.refills = refills
            self.contactEmailText = contactEmailText
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareProtocolSlotView(_ item: DefaultCareProtocolSlot) -> DefaultCareProtocolSlotView {
        return DefaultCareProtocolSlotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            archived: "\(item.archived)",
            discountText: String(format: "%.2f", item.discount),
            currency: Kit.Text.truncate(item.currency, limit: 64),
            refills: String(item.refills),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 80),
            createdAt: String(item.createdAt),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareProtocolSlotViews(_ items: [DefaultCareProtocolSlot]) -> [DefaultCareProtocolSlotView] {
        var views: [DefaultCareProtocolSlotView] = []
        for item in items {
            views.append(toDefaultCareProtocolSlotView(item))
        }
        return views
    }

    static func sumDefaultCareProtocolSlotView(_ view: DefaultCareProtocolSlotView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + Double(parsedRefills) + Double(parsedCreatedAt)
    }
}
