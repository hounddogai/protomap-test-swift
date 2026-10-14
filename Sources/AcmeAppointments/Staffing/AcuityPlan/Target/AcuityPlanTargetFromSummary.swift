import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryOvertimeSummariesForTarget(_ items: [PrimaryOvertimeSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveAcuityPlanTargetsFromSummary(_ items: [PrimaryOvertimeSummary]) -> [AcuityPlanTarget] {
        var out: [AcuityPlanTarget] = []
        for item in items {
            let derived = newAcuityPlanTarget(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateAcuityPlanTarget(_ item: AcuityPlanTarget) -> Double {
        return seasonalOvertimeDigestWeight(3, active: true)
    }
}
