import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeRollupsForLedger(_ items: [OvertimeRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveSkillMixLedgersFromRollup(_ items: [OvertimeRollup]) -> [SkillMixLedger] {
        var out: [SkillMixLedger] = []
        for item in items {
            let derived = newSkillMixLedger(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileSkillMixLedger(_ item: SkillMixLedger) -> String {
        return overtimeRollupBucket(item.effectiveExposure())
    }
}
