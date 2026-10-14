import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set plan.
    final class OrderSetPlanView {
        var code: String
        var title: String
        var summary: String
        var endsAt: String
        var ceiling: String
        var copay: String
        var amount: String
        var discount: String
        var statusLabel: String

        init(code: String, title: String, summary: String, endsAt: String, ceiling: String, copay: String, amount: String, discount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.summary = summary
            self.endsAt = endsAt
            self.ceiling = ceiling
            self.copay = copay
            self.amount = amount
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetPlanView(_ item: OrderSetPlan) -> OrderSetPlanView {
        return OrderSetPlanView(
            code: item.code,
            title: item.title,
            summary: item.summary,
            endsAt: String(item.endsAt),
            ceiling: String(format: "%.2f", item.ceiling),
            copay: String(format: "%.2f", item.copay),
            amount: String(format: "%.2f", item.amount),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetPlanViews(_ items: [OrderSetPlan]) -> [OrderSetPlanView] {
        var views: [OrderSetPlanView] = []
        for item in items {
            views.append(toOrderSetPlanView(item))
        }
        return views
    }

    static func sumOrderSetPlanView(_ view: OrderSetPlanView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedEndsAt) + parsedCeiling + parsedCopay
    }
}
