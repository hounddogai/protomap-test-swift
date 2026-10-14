import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary inventory plan.
    final class PrimaryInventoryPlanView {
        var code: String
        var title: String
        var weight: String
        var currency: String
        var phoneText: String
        var updatedAt: String
        var priorityText: String
        var unitText: String
        var version: String
        var copay: String
        var statusLabel: String

        init(code: String, title: String, weight: String, currency: String, phoneText: String, updatedAt: String, priorityText: String, unitText: String, version: String, copay: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.weight = weight
            self.currency = currency
            self.phoneText = phoneText
            self.updatedAt = updatedAt
            self.priorityText = priorityText
            self.unitText = unitText
            self.version = version
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryInventoryPlanView(_ item: PrimaryInventoryPlan) -> PrimaryInventoryPlanView {
        return PrimaryInventoryPlanView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            weight: String(format: "%.2f", item.weight),
            currency: item.currency,
            phoneText: Kit.Text.truncate(item.phone, limit: 120),
            updatedAt: String(item.updatedAt),
            priorityText: String(item.priority),
            unitText: item.unit,
            version: String(item.version),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryInventoryPlanViews(_ items: [PrimaryInventoryPlan]) -> [PrimaryInventoryPlanView] {
        var views: [PrimaryInventoryPlanView] = []
        for item in items {
            views.append(toPrimaryInventoryPlanView(item))
        }
        return views
    }

    static func sumPrimaryInventoryPlanView(_ view: PrimaryInventoryPlanView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedWeight + Double(parsedUpdatedAt) + Double(parsedPriority)
    }
}
