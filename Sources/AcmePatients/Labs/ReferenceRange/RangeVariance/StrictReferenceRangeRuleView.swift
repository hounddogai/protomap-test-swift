import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a strict reference range rule.
    final class StrictReferenceRangeRuleView {
        var code: String
        var name: String
        var endsAt: String
        var label: String
        var versionText: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, endsAt: String, label: String, versionText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.label = label
            self.versionText = versionText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toStrictReferenceRangeRuleView(_ item: StrictReferenceRangeRule) -> StrictReferenceRangeRuleView {
        return StrictReferenceRangeRuleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            endsAt: String(item.endsAt),
            label: item.label,
            versionText: String(item.version),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictReferenceRangeRuleViews(_ items: [StrictReferenceRangeRule]) -> [StrictReferenceRangeRuleView] {
        var views: [StrictReferenceRangeRuleView] = []
        for item in items {
            views.append(toStrictReferenceRangeRuleView(item))
        }
        return views
    }

    static func sumStrictReferenceRangeRuleView(_ view: StrictReferenceRangeRuleView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedVersion) + Double(parsedQuantity)
    }
}
