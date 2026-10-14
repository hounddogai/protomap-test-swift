import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixRecordsForAdjustment(_ items: [SkillMixRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveFallbackFloatPoolAdjustmentsFromRecord(_ items: [SkillMixRecord]) -> [FallbackFloatPoolAdjustment] {
        var out: [FallbackFloatPoolAdjustment] = []
        for item in items {
            let derived = newFallbackFloatPoolAdjustment(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectFallbackFloatPoolAdjustment(_ item: FallbackFloatPoolAdjustment) -> String {
        return pendingSkillMixPreferenceBucket(item.netVolume())
    }
}
