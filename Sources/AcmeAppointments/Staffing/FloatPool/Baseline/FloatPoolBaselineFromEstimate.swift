import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledSkillMixEstimatesForBaseline(_ items: [ScheduledSkillMixEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveFloatPoolBaselinesFromEstimate(_ items: [ScheduledSkillMixEstimate]) -> [FloatPoolBaseline] {
        var out: [FloatPoolBaseline] = []
        for item in items {
            let derived = newFloatPoolBaseline(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeFloatPoolBaseline(_ item: FloatPoolBaseline) -> String {
        return pendingSkillMixDigestBucket(item.weightedTotal())
    }
}
