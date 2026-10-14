import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a strict worklist plan.
    final class StrictWorklistPlanView {
        var code: String
        var title: String
        var costText: String
        var ward: String
        var priorityText: String
        var visibleText: String
        var floorValueText: String
        var label: String
        var bed: String
        var statusLabel: String

        init(code: String, title: String, costText: String, ward: String, priorityText: String, visibleText: String, floorValueText: String, label: String, bed: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.costText = costText
            self.ward = ward
            self.priorityText = priorityText
            self.visibleText = visibleText
            self.floorValueText = floorValueText
            self.label = label
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toStrictWorklistPlanView(_ item: StrictWorklistPlan) -> StrictWorklistPlanView {
        return StrictWorklistPlanView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            costText: String(format: "%.2f", item.cost),
            ward: Kit.Text.truncate(item.ward, limit: 120),
            priorityText: String(item.priority),
            visibleText: "\(item.visible)",
            floorValueText: String(format: "%.2f", item.floorValue),
            label: Kit.Text.truncate(item.label, limit: 80),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictWorklistPlanViews(_ items: [StrictWorklistPlan]) -> [StrictWorklistPlanView] {
        var views: [StrictWorklistPlanView] = []
        for item in items {
            views.append(toStrictWorklistPlanView(item))
        }
        return views
    }

    static func sumStrictWorklistPlanView(_ view: StrictWorklistPlanView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedCost + Double(parsedPriority) + parsedFloorValue
    }
}
