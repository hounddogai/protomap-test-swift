import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeLegacySkillMixMilestonesForAgreement(_ items: [LegacySkillMixMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func derivePendingOvertimeAgreementsFromMilestone(_ items: [LegacySkillMixMilestone]) -> [PendingOvertimeAgreement] {
        var out: [PendingOvertimeAgreement] = []
        for item in items {
            let derived = newPendingOvertimeAgreement(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPendingOvertimeAgreement(_ item: PendingOvertimeAgreement) -> String {
        return legacySkillMixMilestoneBucket(item.adjustedValue())
    }
}
