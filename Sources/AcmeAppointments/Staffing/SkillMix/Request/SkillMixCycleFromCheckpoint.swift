import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFallbackOvertimeCheckpointsForCycle(_ items: [FallbackOvertimeCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSkillMixCyclesFromCheckpoint(_ items: [FallbackOvertimeCheckpoint]) -> [SkillMixCycle] {
        var out: [SkillMixCycle] = []
        for item in items {
            let derived = newSkillMixCycle(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applySkillMixCycle(_ item: SkillMixCycle) -> String {
        return classifyLenientOvertimeProposal(item.effectiveVolume())
    }
}
