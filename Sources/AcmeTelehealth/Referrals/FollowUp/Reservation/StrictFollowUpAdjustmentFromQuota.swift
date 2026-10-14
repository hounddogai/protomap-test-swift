import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryEligibilityQuotasForAdjustment(_ items: [PrimaryEligibilityQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveStrictFollowUpAdjustmentsFromQuota(_ items: [PrimaryEligibilityQuota]) -> [StrictFollowUpAdjustment] {
        var out: [StrictFollowUpAdjustment] = []
        for item in items {
            let derived = newStrictFollowUpAdjustment(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeStrictFollowUpAdjustment(_ item: StrictFollowUpAdjustment) -> Double {
        return cappedEligibilityVarianceWeight(2, active: true)
    }
}
