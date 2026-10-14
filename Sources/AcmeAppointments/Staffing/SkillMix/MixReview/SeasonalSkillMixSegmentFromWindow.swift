import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAcuityPlanWindowsForSegment(_ items: [AcuityPlanWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveSeasonalSkillMixSegmentsFromWindow(_ items: [AcuityPlanWindow]) -> [SeasonalSkillMixSegment] {
        var out: [SeasonalSkillMixSegment] = []
        for item in items {
            let derived = newSeasonalSkillMixSegment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifySeasonalSkillMixSegmentExtra(_ item: SeasonalSkillMixSegment) -> String {
        return normalizeAcuityPlanSegmentCode(item.code)
    }
}
