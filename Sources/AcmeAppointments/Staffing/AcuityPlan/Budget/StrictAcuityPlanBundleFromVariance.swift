import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeManualOvertimeVariancesForBundle(_ items: [ManualOvertimeVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveStrictAcuityPlanBundlesFromVariance(_ items: [ManualOvertimeVariance]) -> [StrictAcuityPlanBundle] {
        var out: [StrictAcuityPlanBundle] = []
        for item in items {
            let derived = newStrictAcuityPlanBundle(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectStrictAcuityPlanBundle(_ item: StrictAcuityPlanBundle) -> String {
        return lenientOvertimeAssignmentBucket(item.projectedVolume())
    }
}
