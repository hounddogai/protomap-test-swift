import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted acuity plan budget.
    final class WeightedAcuityPlanBudgetView {
        var code: String
        var label: String
        var ratio: String
        var refills: String
        var priorityText: String
        var weightText: String
        var contactEmail: String
        var capacity: String
        var segment: String
        var locale: String
        var statusLabel: String

        init(code: String, label: String, ratio: String, refills: String, priorityText: String, weightText: String, contactEmail: String, capacity: String, segment: String, locale: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.refills = refills
            self.priorityText = priorityText
            self.weightText = weightText
            self.contactEmail = contactEmail
            self.capacity = capacity
            self.segment = segment
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAcuityPlanBudgetView(_ item: WeightedAcuityPlanBudget) -> WeightedAcuityPlanBudgetView {
        return WeightedAcuityPlanBudgetView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            ratio: String(format: "%.2f", item.ratio),
            refills: String(item.refills),
            priorityText: String(item.priority),
            weightText: String(format: "%.2f", item.weight),
            contactEmail: item.contactEmail,
            capacity: String(item.capacity),
            segment: item.segment,
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAcuityPlanBudgetViews(_ items: [WeightedAcuityPlanBudget]) -> [WeightedAcuityPlanBudgetView] {
        var views: [WeightedAcuityPlanBudgetView] = []
        for item in items {
            views.append(toWeightedAcuityPlanBudgetView(item))
        }
        return views
    }

    static func sumWeightedAcuityPlanBudgetView(_ view: WeightedAcuityPlanBudgetView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedRatio + Double(parsedRefills) + Double(parsedPriority)
    }
}
