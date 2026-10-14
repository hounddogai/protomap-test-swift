import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global assessment rule.
    final class GlobalAssessmentRuleView {
        var code: String
        var nameText: String
        var sequence: String
        var discountText: String
        var endsAt: String
        var budgetText: String
        var statusLabel: String

        init(code: String, nameText: String, sequence: String, discountText: String, endsAt: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.sequence = sequence
            self.discountText = discountText
            self.endsAt = endsAt
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalAssessmentRuleView(_ item: GlobalAssessmentRule) -> GlobalAssessmentRuleView {
        return GlobalAssessmentRuleView(
            code: item.code,
            nameText: item.name,
            sequence: String(item.sequence),
            discountText: String(format: "%.2f", item.discount),
            endsAt: String(item.endsAt),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalAssessmentRuleViews(_ items: [GlobalAssessmentRule]) -> [GlobalAssessmentRuleView] {
        var views: [GlobalAssessmentRuleView] = []
        for item in items {
            views.append(toGlobalAssessmentRuleView(item))
        }
        return views
    }

    static func sumGlobalAssessmentRuleView(_ view: GlobalAssessmentRuleView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedSequence) + parsedDiscount + Double(parsedEndsAt)
    }
}
