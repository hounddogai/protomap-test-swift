import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient discharge plan milestone.
    final class LenientDischargePlanMilestoneView {
        var codeText: String
        var name: String
        var approved: String
        var priorityText: String
        var budget: String
        var discount: String
        var visible: String
        var limitText: String
        var segment: String
        var statusLabel: String

        init(codeText: String, name: String, approved: String, priorityText: String, budget: String, discount: String, visible: String, limitText: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.approved = approved
            self.priorityText = priorityText
            self.budget = budget
            self.discount = discount
            self.visible = visible
            self.limitText = limitText
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toLenientDischargePlanMilestoneView(_ item: LenientDischargePlanMilestone) -> LenientDischargePlanMilestoneView {
        return LenientDischargePlanMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            approved: "\(item.approved)",
            priorityText: String(item.priority),
            budget: String(format: "%.2f", item.budget),
            discount: String(format: "%.2f", item.discount),
            visible: "\(item.visible)",
            limitText: String(item.limit),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientDischargePlanMilestoneViews(_ items: [LenientDischargePlanMilestone]) -> [LenientDischargePlanMilestoneView] {
        var views: [LenientDischargePlanMilestoneView] = []
        for item in items {
            views.append(toLenientDischargePlanMilestoneView(item))
        }
        return views
    }

    static func sumLenientDischargePlanMilestoneView(_ view: LenientDischargePlanMilestoneView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedPriority) + parsedBudget + parsedDiscount
    }
}
