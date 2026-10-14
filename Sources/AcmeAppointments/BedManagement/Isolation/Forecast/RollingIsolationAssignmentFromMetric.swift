import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackDischargePlanMetricsForAssignment(_ items: [FallbackDischargePlanMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRollingIsolationAssignmentsFromMetric(_ items: [FallbackDischargePlanMetric]) -> [RollingIsolationAssignment] {
        var out: [RollingIsolationAssignment] = []
        for item in items {
            let derived = newRollingIsolationAssignment(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateRollingIsolationAssignment(_ item: RollingIsolationAssignment) -> Double {
        return fallbackDischargePlanMetricWeight(1, active: true)
    }
}
