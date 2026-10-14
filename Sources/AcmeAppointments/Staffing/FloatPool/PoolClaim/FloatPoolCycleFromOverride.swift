import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanOverridesForCycle(_ items: [AcuityPlanOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveFloatPoolCyclesFromOverride(_ items: [AcuityPlanOverride]) -> [FloatPoolCycle] {
        var out: [FloatPoolCycle] = []
        for item in items {
            let derived = newFloatPoolCycle(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceFloatPoolCycle(_ item: FloatPoolCycle) -> Double {
        return primaryAcuityPlanPolicyWeight(4, active: true)
    }
}
