import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set rule.
    final class OrderSetRuleView {
        var codeText: String
        var name: String
        var diagnosisCode: String
        var sequence: String
        var endsAt: String
        var title: String
        var updatedAt: String
        var reviewerText: String
        var maximum: String
        var phone: String
        var statusLabel: String

        init(codeText: String, name: String, diagnosisCode: String, sequence: String, endsAt: String, title: String, updatedAt: String, reviewerText: String, maximum: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.endsAt = endsAt
            self.title = title
            self.updatedAt = updatedAt
            self.reviewerText = reviewerText
            self.maximum = maximum
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetRuleView(_ item: OrderSetRule) -> OrderSetRuleView {
        return OrderSetRuleView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            sequence: String(item.sequence),
            endsAt: String(item.endsAt),
            title: item.title,
            updatedAt: String(item.updatedAt),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetRuleViews(_ items: [OrderSetRule]) -> [OrderSetRuleView] {
        var views: [OrderSetRuleView] = []
        for item in items {
            views.append(toOrderSetRuleView(item))
        }
        return views
    }

    static func sumOrderSetRuleView(_ view: OrderSetRuleView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedSequence) + Double(parsedEndsAt) + Double(parsedUpdatedAt)
    }
}
