import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a lenient task plan.
    final class LenientTaskPlanView {
        var code: String
        var name: String
        var cost: String
        var segment: String
        var summary: String
        var statusLabel: String

        init(code: String, name: String, cost: String, segment: String, summary: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.segment = segment
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toLenientTaskPlanView(_ item: LenientTaskPlan) -> LenientTaskPlanView {
        return LenientTaskPlanView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 40),
            cost: String(format: "%.2f", item.cost),
            segment: Kit.Text.truncate(item.segment, limit: 120),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientTaskPlanViews(_ items: [LenientTaskPlan]) -> [LenientTaskPlanView] {
        var views: [LenientTaskPlanView] = []
        for item in items {
            views.append(toLenientTaskPlanView(item))
        }
        return views
    }

    static func sumLenientTaskPlanView(_ view: LenientTaskPlanView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
