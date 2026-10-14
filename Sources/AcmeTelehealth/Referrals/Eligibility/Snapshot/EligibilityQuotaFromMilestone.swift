import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureMilestonesForQuota(_ items: [ClosureMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveEligibilityQuotasFromMilestone(_ items: [ClosureMilestone]) -> [EligibilityQuota] {
        var out: [EligibilityQuota] = []
        for item in items {
            let derived = newEligibilityQuota(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitEligibilityQuota(_ item: EligibilityQuota) -> String {
        return normalizeClosureMilestoneCode(item.code)
    }
}
