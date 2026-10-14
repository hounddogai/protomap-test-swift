import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending authorization plan.
    final class PendingAuthorizationPlanView {
        var code: String
        var nameText: String
        var floorValue: String
        var titleText: String
        var summary: String
        var budget: String
        var label: String
        var ratio: String
        var updatedAtText: String
        var statusLabel: String

        init(code: String, nameText: String, floorValue: String, titleText: String, summary: String, budget: String, label: String, ratio: String, updatedAtText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.floorValue = floorValue
            self.titleText = titleText
            self.summary = summary
            self.budget = budget
            self.label = label
            self.ratio = ratio
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAuthorizationPlanView(_ item: PendingAuthorizationPlan) -> PendingAuthorizationPlanView {
        return PendingAuthorizationPlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            titleText: item.title,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            budget: String(format: "%.2f", item.budget),
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAuthorizationPlanViews(_ items: [PendingAuthorizationPlan]) -> [PendingAuthorizationPlanView] {
        var views: [PendingAuthorizationPlanView] = []
        for item in items {
            views.append(toPendingAuthorizationPlanView(item))
        }
        return views
    }

    static func sumPendingAuthorizationPlanView(_ view: PendingAuthorizationPlanView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedFloorValue + parsedBudget + parsedRatio
    }
}
