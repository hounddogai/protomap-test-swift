import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftRollupsForMetric(_ items: [ShiftRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveSeasonalShiftMetricsFromRollup(_ items: [ShiftRollup]) -> [SeasonalShiftMetric] {
        var out: [SeasonalShiftMetric] = []
        for item in items {
            let derived = newSeasonalShiftMetric(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreSeasonalShiftMetric(_ item: SeasonalShiftMetric) -> String {
        return classifyShiftTier(item.effectiveLoad())
    }
}
