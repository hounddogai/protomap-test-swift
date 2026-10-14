import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalFloatPoolTargetsForCycle(_ items: [GlobalFloatPoolTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCappedSkillMixCyclesFromTarget(_ items: [GlobalFloatPoolTarget]) -> [CappedSkillMixCycle] {
        var out: [CappedSkillMixCycle] = []
        for item in items {
            let derived = newCappedSkillMixCycle(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCappedSkillMixCycle(_ item: CappedSkillMixCycle) -> String {
        return globalFloatPoolTargetBucket(item.adjustedTotal())
    }
}
