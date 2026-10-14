import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy goal segment.
    final class LegacyGoalSegmentView {
        var code: String
        var labelText: String
        var threshold: String
        var cost: String
        var unit: String
        var pinned: String
        var capacityText: String
        var diagnosisCode: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, labelText: String, threshold: String, cost: String, unit: String, pinned: String, capacityText: String, diagnosisCode: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.threshold = threshold
            self.cost = cost
            self.unit = unit
            self.pinned = pinned
            self.capacityText = capacityText
            self.diagnosisCode = diagnosisCode
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyGoalSegmentView(_ item: LegacyGoalSegment) -> LegacyGoalSegmentView {
        return LegacyGoalSegmentView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            threshold: String(format: "%.2f", item.threshold),
            cost: String(format: "%.2f", item.cost),
            unit: item.unit,
            pinned: "\(item.pinned)",
            capacityText: String(item.capacity),
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyGoalSegmentViews(_ items: [LegacyGoalSegment]) -> [LegacyGoalSegmentView] {
        var views: [LegacyGoalSegmentView] = []
        for item in items {
            views.append(toLegacyGoalSegmentView(item))
        }
        return views
    }

    static func sumLegacyGoalSegmentView(_ view: LegacyGoalSegmentView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedThreshold + parsedCost + Double(parsedCapacity)
    }
}
