import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling follow up rule.
    final class RollingFollowUpRuleView {
        var code: String
        var name: String
        var margin: String
        var contactEmail: String
        var quantity: String
        var active: String
        var statusLabel: String

        init(code: String, name: String, margin: String, contactEmail: String, quantity: String, active: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.margin = margin
            self.contactEmail = contactEmail
            self.quantity = quantity
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toRollingFollowUpRuleView(_ item: RollingFollowUpRule) -> RollingFollowUpRuleView {
        return RollingFollowUpRuleView(
            code: item.code,
            name: item.name,
            margin: String(format: "%.2f", item.margin),
            contactEmail: item.contactEmail,
            quantity: String(item.quantity),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingFollowUpRuleViews(_ items: [RollingFollowUpRule]) -> [RollingFollowUpRuleView] {
        var views: [RollingFollowUpRuleView] = []
        for item in items {
            views.append(toRollingFollowUpRuleView(item))
        }
        return views
    }

    static func sumRollingFollowUpRuleView(_ view: RollingFollowUpRuleView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedMargin + Double(parsedQuantity)
    }
}
