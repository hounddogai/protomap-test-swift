import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling specimen rule.
    final class RollingSpecimenRuleView {
        var code: String
        var name: String
        var payer: String
        var facility: String
        var limitText: String
        var contactEmail: String
        var currencyText: String
        var quantity: String
        var graceDays: String
        var phone: String
        var statusLabel: String

        init(code: String, name: String, payer: String, facility: String, limitText: String, contactEmail: String, currencyText: String, quantity: String, graceDays: String, phone: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.payer = payer
            self.facility = facility
            self.limitText = limitText
            self.contactEmail = contactEmail
            self.currencyText = currencyText
            self.quantity = quantity
            self.graceDays = graceDays
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSpecimenRuleView(_ item: RollingSpecimenRule) -> RollingSpecimenRuleView {
        return RollingSpecimenRuleView(
            code: item.code,
            name: item.name,
            payer: item.payer,
            facility: item.facility,
            limitText: String(item.limit),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            currencyText: Kit.Text.truncate(item.currency, limit: 40),
            quantity: String(item.quantity),
            graceDays: String(item.graceDays),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSpecimenRuleViews(_ items: [RollingSpecimenRule]) -> [RollingSpecimenRuleView] {
        var views: [RollingSpecimenRuleView] = []
        for item in items {
            views.append(toRollingSpecimenRuleView(item))
        }
        return views
    }

    static func sumRollingSpecimenRuleView(_ view: RollingSpecimenRuleView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedLimit) + Double(parsedQuantity) + Double(parsedGraceDays)
    }
}
