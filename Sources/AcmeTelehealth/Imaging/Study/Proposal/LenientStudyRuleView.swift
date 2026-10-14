import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a lenient study rule.
    final class LenientStudyRuleView {
        var code: String
        var label: String
        var discount: String
        var priorityText: String
        var quantity: String
        var statusLabel: String

        init(code: String, label: String, discount: String, priorityText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.priorityText = priorityText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toLenientStudyRuleView(_ item: LenientStudyRule) -> LenientStudyRuleView {
        return LenientStudyRuleView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            priorityText: String(item.priority),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientStudyRuleViews(_ items: [LenientStudyRule]) -> [LenientStudyRuleView] {
        var views: [LenientStudyRuleView] = []
        for item in items {
            views.append(toLenientStudyRuleView(item))
        }
        return views
    }

    static func sumLenientStudyRuleView(_ view: LenientStudyRuleView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedDiscount + Double(parsedPriority) + Double(parsedQuantity)
    }
}
