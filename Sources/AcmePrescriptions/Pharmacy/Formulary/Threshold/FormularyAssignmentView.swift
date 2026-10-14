import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary assignment.
    final class FormularyAssignmentView {
        var code: String
        var name: String
        var budgetText: String
        var revision: String
        var contactEmailText: String
        var amount: String
        var statusLabel: String

        init(code: String, name: String, budgetText: String, revision: String, contactEmailText: String, amount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budgetText = budgetText
            self.revision = revision
            self.contactEmailText = contactEmailText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyAssignmentView(_ item: FormularyAssignment) -> FormularyAssignmentView {
        return FormularyAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            budgetText: String(format: "%.2f", item.budget),
            revision: String(item.revision),
            contactEmailText: item.contactEmail,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyAssignmentViews(_ items: [FormularyAssignment]) -> [FormularyAssignmentView] {
        var views: [FormularyAssignmentView] = []
        for item in items {
            views.append(toFormularyAssignmentView(item))
        }
        return views
    }

    static func sumFormularyAssignmentView(_ view: FormularyAssignmentView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedBudget + Double(parsedRevision) + parsedAmount
    }
}
