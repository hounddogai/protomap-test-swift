import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixPlansForSegment(_ items: [SkillMixPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAcuityPlanSegmentsFromPlan(_ items: [SkillMixPlan]) -> [AcuityPlanSegment] {
        var out: [AcuityPlanSegment] = []
        for item in items {
            let derived = newAcuityPlanSegment(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveAcuityPlanSegment(_ item: AcuityPlanSegment) -> String {
        return normalizeSkillMixClaimCode(item.code)
    }
}
