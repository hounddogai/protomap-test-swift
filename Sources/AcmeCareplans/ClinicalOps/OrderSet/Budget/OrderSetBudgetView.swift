import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set budget.
    final class OrderSetBudgetView {
        var codeText: String
        var name: String
        var archived: String
        var ownerID: String
        var contactEmailText: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, name: String, archived: String, ownerID: String, contactEmailText: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.archived = archived
            self.ownerID = ownerID
            self.contactEmailText = contactEmailText
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetBudgetView(_ item: OrderSetBudget) -> OrderSetBudgetView {
        return OrderSetBudgetView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            archived: "\(item.archived)",
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 64),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetBudgetViews(_ items: [OrderSetBudget]) -> [OrderSetBudgetView] {
        var views: [OrderSetBudgetView] = []
        for item in items {
            views.append(toOrderSetBudgetView(item))
        }
        return views
    }

    static func sumOrderSetBudgetView(_ view: OrderSetBudgetView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
