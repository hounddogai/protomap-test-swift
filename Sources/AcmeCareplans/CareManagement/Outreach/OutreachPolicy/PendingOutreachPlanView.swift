import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending outreach plan.
    final class PendingOutreachPlanView {
        var code: String
        var titleText: String
        var visible: String
        var activeText: String
        var phoneText: String
        var ceilingText: String
        var ratioText: String
        var statusLabel: String

        init(code: String, titleText: String, visible: String, activeText: String, phoneText: String, ceilingText: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.visible = visible
            self.activeText = activeText
            self.phoneText = phoneText
            self.ceilingText = ceilingText
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingOutreachPlanView(_ item: PendingOutreachPlan) -> PendingOutreachPlanView {
        return PendingOutreachPlanView(
            code: item.code,
            titleText: item.title,
            visible: "\(item.visible)",
            activeText: "\(item.active)",
            phoneText: item.phone,
            ceilingText: String(format: "%.2f", item.ceiling),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingOutreachPlanViews(_ items: [PendingOutreachPlan]) -> [PendingOutreachPlanView] {
        var views: [PendingOutreachPlanView] = []
        for item in items {
            views.append(toPendingOutreachPlanView(item))
        }
        return views
    }

    static func sumPendingOutreachPlanView(_ view: PendingOutreachPlanView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedCeiling + parsedRatio
    }
}
