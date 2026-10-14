import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched statement agreement.
    final class BatchedStatementAgreementView {
        var code: String
        var name: String
        var categoryText: String
        var margin: String
        var budget: String
        var contactEmailText: String
        var copay: String
        var ratioText: String
        var statusLabel: String

        init(code: String, name: String, categoryText: String, margin: String, budget: String, contactEmailText: String, copay: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.categoryText = categoryText
            self.margin = margin
            self.budget = budget
            self.contactEmailText = contactEmailText
            self.copay = copay
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedStatementAgreementView(_ item: BatchedStatementAgreement) -> BatchedStatementAgreementView {
        return BatchedStatementAgreementView(
            code: item.code,
            name: item.name,
            categoryText: item.category,
            margin: String(format: "%.2f", item.margin),
            budget: String(format: "%.2f", item.budget),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 80),
            copay: String(format: "%.2f", item.copay),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedStatementAgreementViews(_ items: [BatchedStatementAgreement]) -> [BatchedStatementAgreementView] {
        var views: [BatchedStatementAgreementView] = []
        for item in items {
            views.append(toBatchedStatementAgreementView(item))
        }
        return views
    }

    static func sumBatchedStatementAgreementView(_ view: BatchedStatementAgreementView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedMargin + parsedBudget + parsedCopay
    }
}
