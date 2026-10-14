import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy closure cycle.
    final class LegacyClosureCycleView {
        var code: String
        var label: String
        var allergy: String
        var floorValue: String
        var unit: String
        var windowDaysText: String
        var segment: String
        var costText: String
        var approved: String
        var statusLabel: String

        init(code: String, label: String, allergy: String, floorValue: String, unit: String, windowDaysText: String, segment: String, costText: String, approved: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.floorValue = floorValue
            self.unit = unit
            self.windowDaysText = windowDaysText
            self.segment = segment
            self.costText = costText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyClosureCycleView(_ item: LegacyClosureCycle) -> LegacyClosureCycleView {
        return LegacyClosureCycleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            allergy: item.allergy,
            floorValue: String(format: "%.2f", item.floorValue),
            unit: item.unit,
            windowDaysText: String(item.windowDays),
            segment: item.segment,
            costText: String(format: "%.2f", item.cost),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyClosureCycleViews(_ items: [LegacyClosureCycle]) -> [LegacyClosureCycleView] {
        var views: [LegacyClosureCycleView] = []
        for item in items {
            views.append(toLegacyClosureCycleView(item))
        }
        return views
    }

    static func sumLegacyClosureCycleView(_ view: LegacyClosureCycleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedFloorValue + Double(parsedWindowDays) + parsedCost
    }
}
