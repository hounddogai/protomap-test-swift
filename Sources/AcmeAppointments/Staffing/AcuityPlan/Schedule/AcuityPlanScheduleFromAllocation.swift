import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSkillMixAllocationsForSchedule(_ items: [SkillMixAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveAcuityPlanSchedulesFromAllocation(_ items: [SkillMixAllocation]) -> [AcuityPlanSchedule] {
        var out: [AcuityPlanSchedule] = []
        for item in items {
            let derived = newAcuityPlanSchedule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankAcuityPlanSchedule(_ item: AcuityPlanSchedule) -> String {
        return normalizeCappedSkillMixSlotCode(item.code)
    }
}
