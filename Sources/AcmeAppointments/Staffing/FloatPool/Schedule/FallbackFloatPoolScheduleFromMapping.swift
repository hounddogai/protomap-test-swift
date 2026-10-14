import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimarySkillMixMappingsForSchedule(_ items: [PrimarySkillMixMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveFallbackFloatPoolSchedulesFromMapping(_ items: [PrimarySkillMixMapping]) -> [FallbackFloatPoolSchedule] {
        var out: [FallbackFloatPoolSchedule] = []
        for item in items {
            let derived = newFallbackFloatPoolSchedule(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveFallbackFloatPoolSchedule(_ item: FallbackFloatPoolSchedule) -> String {
        return classifyCappedSkillMixAudit(item.adjustedExposure())
    }
}
