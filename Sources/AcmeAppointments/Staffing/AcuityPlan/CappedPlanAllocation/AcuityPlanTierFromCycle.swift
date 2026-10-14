import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeBatchedSkillMixCyclesForTier(_ items: [BatchedSkillMixCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveAcuityPlanTiersFromCycle(_ items: [BatchedSkillMixCycle]) -> [AcuityPlanTier] {
        var out: [AcuityPlanTier] = []
        for item in items {
            let derived = newAcuityPlanTier(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankAcuityPlanTier(_ item: AcuityPlanTier) -> String {
        return normalizeBatchedSkillMixCycleCode(item.code)
    }
}
