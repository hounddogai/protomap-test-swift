import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted assessment budget.
    final class WeightedAssessmentBudgetView {
        var code: String
        var title: String
        var capacityText: String
        var quantity: String
        var rate: String
        var discount: String
        var acuity: String
        var archivedText: String
        var visible: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, capacityText: String, quantity: String, rate: String, discount: String, acuity: String, archivedText: String, visible: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.capacityText = capacityText
            self.quantity = quantity
            self.rate = rate
            self.discount = discount
            self.acuity = acuity
            self.archivedText = archivedText
            self.visible = visible
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAssessmentBudgetView(_ item: WeightedAssessmentBudget) -> WeightedAssessmentBudgetView {
        return WeightedAssessmentBudgetView(
            code: item.code,
            title: item.title,
            capacityText: String(item.capacity),
            quantity: String(item.quantity),
            rate: String(format: "%.2f", item.rate),
            discount: String(format: "%.2f", item.discount),
            acuity: String(item.acuity),
            archivedText: "\(item.archived)",
            visible: "\(item.visible)",
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAssessmentBudgetViews(_ items: [WeightedAssessmentBudget]) -> [WeightedAssessmentBudgetView] {
        var views: [WeightedAssessmentBudgetView] = []
        for item in items {
            views.append(toWeightedAssessmentBudgetView(item))
        }
        return views
    }

    static func sumWeightedAssessmentBudgetView(_ view: WeightedAssessmentBudgetView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedCapacity) + Double(parsedQuantity) + parsedRate
    }
}
