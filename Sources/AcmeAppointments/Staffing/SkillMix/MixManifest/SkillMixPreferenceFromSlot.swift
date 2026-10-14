import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeSlotsForPreference(_ items: [OvertimeSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSkillMixPreferencesFromSlot(_ items: [OvertimeSlot]) -> [SkillMixPreference] {
        var out: [SkillMixPreference] = []
        for item in items {
            let derived = newSkillMixPreference(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateSkillMixPreference(_ item: SkillMixPreference) -> Double {
        return overtimeBatchWeight(6, active: true)
    }
}
