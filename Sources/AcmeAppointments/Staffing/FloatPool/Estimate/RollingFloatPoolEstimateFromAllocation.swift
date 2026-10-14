import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledAcuityPlanAllocationsForEstimate(_ items: [ScheduledAcuityPlanAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingFloatPoolEstimatesFromAllocation(_ items: [ScheduledAcuityPlanAllocation]) -> [RollingFloatPoolEstimate] {
        var out: [RollingFloatPoolEstimate] = []
        for item in items {
            let derived = newRollingFloatPoolEstimate(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeRollingFloatPoolEstimate(_ item: RollingFloatPoolEstimate) -> String {
        return classifyScheduledAcuityPlanAllocation(item.netValue())
    }
}
