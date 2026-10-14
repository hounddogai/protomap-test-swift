import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeRollingShiftMetricsForManifest(_ items: [RollingShiftMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveLegacyOvertimeManifestsFromMetric(_ items: [RollingShiftMetric]) -> [LegacyOvertimeManifest] {
        var out: [LegacyOvertimeManifest] = []
        for item in items {
            let derived = newLegacyOvertimeManifest(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyOvertimeManifest(_ item: LegacyOvertimeManifest) -> String {
        return classifyRollingShiftMetric(item.netValue())
    }
}
