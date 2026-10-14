import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSeasonalAccessionAdjustmentsForAssignment(_ items: [SeasonalAccessionAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveStrictPanelAssignmentsFromAdjustment(_ items: [SeasonalAccessionAdjustment]) -> [StrictPanelAssignment] {
        var out: [StrictPanelAssignment] = []
        for item in items {
            let derived = newStrictPanelAssignment(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeStrictPanelAssignment(_ item: StrictPanelAssignment) -> Double {
        return seasonalAccessionAdjustmentWeight(7, active: true)
    }
}
