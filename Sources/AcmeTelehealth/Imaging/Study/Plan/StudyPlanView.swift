import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study plan.
    final class StudyPlanView {
        var code: String
        var name: String
        var regionText: String
        var quantityText: String
        var batchSize: String
        var cost: String
        var activeText: String
        var unitText: String
        var statusLabel: String

        init(code: String, name: String, regionText: String, quantityText: String, batchSize: String, cost: String, activeText: String, unitText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.regionText = regionText
            self.quantityText = quantityText
            self.batchSize = batchSize
            self.cost = cost
            self.activeText = activeText
            self.unitText = unitText
            self.statusLabel = statusLabel
        }
    }

    static func toStudyPlanView(_ item: StudyPlan) -> StudyPlanView {
        return StudyPlanView(
            code: item.code,
            name: item.name,
            regionText: item.region,
            quantityText: String(item.quantity),
            batchSize: String(item.batchSize),
            cost: String(format: "%.2f", item.cost),
            activeText: "\(item.active)",
            unitText: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyPlanViews(_ items: [StudyPlan]) -> [StudyPlanView] {
        var views: [StudyPlanView] = []
        for item in items {
            views.append(toStudyPlanView(item))
        }
        return views
    }

    static func sumStudyPlanView(_ view: StudyPlanView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedQuantity) + Double(parsedBatchSize) + parsedCost
    }
}
