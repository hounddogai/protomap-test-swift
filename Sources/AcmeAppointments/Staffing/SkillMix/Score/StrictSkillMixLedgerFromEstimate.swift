import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedSkillMixEstimatesForLedger(_ items: [CappedSkillMixEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveStrictSkillMixLedgersFromEstimate(_ items: [CappedSkillMixEstimate]) -> [StrictSkillMixLedger] {
        var out: [StrictSkillMixLedger] = []
        for item in items {
            let derived = newStrictSkillMixLedger(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeStrictSkillMixLedger(_ item: StrictSkillMixLedger) -> Double {
        return skillMixRollupWeight(3, active: true)
    }
}
