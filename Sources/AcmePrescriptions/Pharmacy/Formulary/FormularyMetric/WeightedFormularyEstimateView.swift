import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted formulary estimate.
    final class WeightedFormularyEstimateView {
        var code: String
        var label: String
        var approvedText: String
        var amount: String
        var quantity: String
        var statusLabel: String

        init(code: String, label: String, approvedText: String, amount: String, quantity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.approvedText = approvedText
            self.amount = amount
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFormularyEstimateView(_ item: WeightedFormularyEstimate) -> WeightedFormularyEstimateView {
        return WeightedFormularyEstimateView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            approvedText: "\(item.approved)",
            amount: String(format: "%.2f", item.amount),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFormularyEstimateViews(_ items: [WeightedFormularyEstimate]) -> [WeightedFormularyEstimateView] {
        var views: [WeightedFormularyEstimateView] = []
        for item in items {
            views.append(toWeightedFormularyEstimateView(item))
        }
        return views
    }

    static func sumWeightedFormularyEstimateView(_ view: WeightedFormularyEstimateView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedAmount + Double(parsedQuantity)
    }
}
