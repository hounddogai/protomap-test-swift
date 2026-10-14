import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary allocation.
    final class FormularyAllocationView {
        var codeText: String
        var label: String
        var quantity: String
        var amountText: String
        var ceiling: String
        var expiresAtText: String
        var approved: String
        var statusLabel: String

        init(codeText: String, label: String, quantity: String, amountText: String, ceiling: String, expiresAtText: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.quantity = quantity
            self.amountText = amountText
            self.ceiling = ceiling
            self.expiresAtText = expiresAtText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyAllocationView(_ item: FormularyAllocation) -> FormularyAllocationView {
        return FormularyAllocationView(
            codeText: item.code,
            label: item.label,
            quantity: String(item.quantity),
            amountText: String(format: "%.2f", item.amount),
            ceiling: String(format: "%.2f", item.ceiling),
            expiresAtText: String(item.expiresAt),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyAllocationViews(_ items: [FormularyAllocation]) -> [FormularyAllocationView] {
        var views: [FormularyAllocationView] = []
        for item in items {
            views.append(toFormularyAllocationView(item))
        }
        return views
    }

    static func sumFormularyAllocationView(_ view: FormularyAllocationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedQuantity) + parsedAmount + parsedCeiling
    }
}
