import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityQuotasForBudget(_ items: [EligibilityQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveEligibilityBudgetsFromQuota(_ items: [EligibilityQuota]) -> [EligibilityBudget] {
        var out: [EligibilityBudget] = []
        for item in items {
            let derived = newEligibilityBudget(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreEligibilityBudget(_ item: EligibilityBudget) -> String {
        return eligibilityQuotaBucket(item.adjustedExposure())
    }
}
