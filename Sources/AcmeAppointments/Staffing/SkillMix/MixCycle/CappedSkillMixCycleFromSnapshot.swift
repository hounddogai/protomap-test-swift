import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryAcuityPlanSnapshotsForCycle(_ items: [PrimaryAcuityPlanSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedSkillMixCyclesFromSnapshot(_ items: [PrimaryAcuityPlanSnapshot]) -> [CappedSkillMixCycle] {
        var out: [CappedSkillMixCycle] = []
        for item in items {
            let derived = newCappedSkillMixCycle(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyCappedSkillMixCycle(_ item: CappedSkillMixCycle) -> String {
        return normalizeAdaptiveAcuityPlanWindowCode(item.code)
    }
}
