import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledFloatPoolPoliciesForVariance(_ items: [ScheduledFloatPoolPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveManualOvertimeVariancesFromPolicy(_ items: [ScheduledFloatPoolPolicy]) -> [ManualOvertimeVariance] {
        var out: [ManualOvertimeVariance] = []
        for item in items {
            let derived = newManualOvertimeVariance(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreManualOvertimeVariance(_ item: ManualOvertimeVariance) -> String {
        return classifyFallbackFloatPoolSchedule(item.weightedTotal())
    }
}
