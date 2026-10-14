import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen budget.
    final class SpecimenBudgetView {
        var code: String
        var label: String
        var weight: String
        var patientRef: String
        var wardText: String
        var costText: String
        var floorValueText: String
        var ratio: String
        var timezone: String
        var statusLabel: String

        init(code: String, label: String, weight: String, patientRef: String, wardText: String, costText: String, floorValueText: String, ratio: String, timezone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weight = weight
            self.patientRef = patientRef
            self.wardText = wardText
            self.costText = costText
            self.floorValueText = floorValueText
            self.ratio = ratio
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenBudgetView(_ item: SpecimenBudget) -> SpecimenBudgetView {
        return SpecimenBudgetView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            patientRef: item.patientRef,
            wardText: Kit.Text.truncate(item.ward, limit: 40),
            costText: String(format: "%.2f", item.cost),
            floorValueText: String(format: "%.2f", item.floorValue),
            ratio: String(format: "%.2f", item.ratio),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenBudgetViews(_ items: [SpecimenBudget]) -> [SpecimenBudgetView] {
        var views: [SpecimenBudgetView] = []
        for item in items {
            views.append(toSpecimenBudgetView(item))
        }
        return views
    }

    static func sumSpecimenBudgetView(_ view: SpecimenBudgetView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedWeight + parsedCost + parsedFloorValue
    }
}
