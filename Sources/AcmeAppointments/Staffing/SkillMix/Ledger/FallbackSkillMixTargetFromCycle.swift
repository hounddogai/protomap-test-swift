import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolCyclesForTarget(_ items: [FloatPoolCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveFallbackSkillMixTargetsFromCycle(_ items: [FloatPoolCycle]) -> [FallbackSkillMixTarget] {
        var out: [FallbackSkillMixTarget] = []
        for item in items {
            let derived = newFallbackSkillMixTarget(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitFallbackSkillMixTarget(_ item: FallbackSkillMixTarget) -> String {
        return floatPoolCycleBucket(item.adjustedLoad())
    }
}
