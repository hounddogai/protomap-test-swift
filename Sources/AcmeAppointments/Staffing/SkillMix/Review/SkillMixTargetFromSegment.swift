import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixSegmentsForTarget(_ items: [SkillMixSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveSkillMixTargetsFromSegment(_ items: [SkillMixSegment]) -> [SkillMixTarget] {
        var out: [SkillMixTarget] = []
        for item in items {
            let derived = newSkillMixTarget(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveSkillMixTarget(_ item: SkillMixTarget) -> String {
        return normalizeTieredSkillMixMetricCode(item.code)
    }
}
