import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending acuity plan milestone.
    final class PendingAcuityPlanMilestoneView {
        var code: String
        var label: String
        var visible: String
        var ownerID: String
        var title: String
        var reviewer: String
        var approved: String
        var quantityText: String
        var statusLabel: String

        init(code: String, label: String, visible: String, ownerID: String, title: String, reviewer: String, approved: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visible = visible
            self.ownerID = ownerID
            self.title = title
            self.reviewer = reviewer
            self.approved = approved
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAcuityPlanMilestoneView(_ item: PendingAcuityPlanMilestone) -> PendingAcuityPlanMilestoneView {
        return PendingAcuityPlanMilestoneView(
            code: item.code,
            label: item.label,
            visible: "\(item.visible)",
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            title: item.title,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            approved: "\(item.approved)",
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAcuityPlanMilestoneViews(_ items: [PendingAcuityPlanMilestone]) -> [PendingAcuityPlanMilestoneView] {
        var views: [PendingAcuityPlanMilestoneView] = []
        for item in items {
            views.append(toPendingAcuityPlanMilestoneView(item))
        }
        return views
    }

    static func sumPendingAcuityPlanMilestoneView(_ view: PendingAcuityPlanMilestoneView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
