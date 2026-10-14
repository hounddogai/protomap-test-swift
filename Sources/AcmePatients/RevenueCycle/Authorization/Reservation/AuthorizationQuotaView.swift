import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization quota.
    final class AuthorizationQuotaView {
        var code: String
        var nameText: String
        var maximum: String
        var contactEmail: String
        var limit: String
        var refills: String
        var discountText: String
        var notes: String
        var quantity: String
        var statusLabel: String

        init(code: String, nameText: String, maximum: String, contactEmail: String, limit: String, refills: String, discountText: String, notes: String, quantity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.maximum = maximum
            self.contactEmail = contactEmail
            self.limit = limit
            self.refills = refills
            self.discountText = discountText
            self.notes = notes
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationQuotaView(_ item: AuthorizationQuota) -> AuthorizationQuotaView {
        return AuthorizationQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            maximum: String(format: "%.2f", item.maximum),
            contactEmail: item.contactEmail,
            limit: String(item.limit),
            refills: String(item.refills),
            discountText: String(format: "%.2f", item.discount),
            notes: item.notes,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationQuotaViews(_ items: [AuthorizationQuota]) -> [AuthorizationQuotaView] {
        var views: [AuthorizationQuotaView] = []
        for item in items {
            views.append(toAuthorizationQuotaView(item))
        }
        return views
    }

    static func sumAuthorizationQuotaView(_ view: AuthorizationQuotaView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedMaximum + Double(parsedLimit) + Double(parsedRefills)
    }
}
