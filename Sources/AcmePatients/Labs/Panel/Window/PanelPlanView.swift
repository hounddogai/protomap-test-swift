import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel plan.
    final class PanelPlanView {
        var code: String
        var title: String
        var refills: String
        var floorValueText: String
        var reviewer: String
        var statusLabel: String

        init(code: String, title: String, refills: String, floorValueText: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refills = refills
            self.floorValueText = floorValueText
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toPanelPlanView(_ item: PanelPlan) -> PanelPlanView {
        return PanelPlanView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 80),
            refills: String(item.refills),
            floorValueText: String(format: "%.2f", item.floorValue),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelPlanViews(_ items: [PanelPlan]) -> [PanelPlanView] {
        var views: [PanelPlanView] = []
        for item in items {
            views.append(toPanelPlanView(item))
        }
        return views
    }

    static func sumPanelPlanView(_ view: PanelPlanView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedRefills) + parsedFloorValue
    }
}
