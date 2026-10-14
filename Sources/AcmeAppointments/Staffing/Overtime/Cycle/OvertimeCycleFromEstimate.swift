import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedSkillMixEstimatesForCycle(_ items: [CappedSkillMixEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveOvertimeCyclesFromEstimate(_ items: [CappedSkillMixEstimate]) -> [OvertimeCycle] {
        var out: [OvertimeCycle] = []
        for item in items {
            let derived = newOvertimeCycle(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeOvertimeCycle(_ item: OvertimeCycle) -> String {
        return skillMixMetricBucket(item.adjustedLoad())
    }
}
