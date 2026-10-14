import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeQuotasForAllocation(_ items: [OvertimeQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveSkillMixAllocationsFromQuota(_ items: [OvertimeQuota]) -> [SkillMixAllocation] {
        var out: [SkillMixAllocation] = []
        for item in items {
            let derived = newSkillMixAllocation(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceSkillMixAllocation(_ item: SkillMixAllocation) -> String {
        return pendingOvertimeAgreementBucket(item.adjustedVolume())
    }
}
