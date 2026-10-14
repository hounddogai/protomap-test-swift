import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRollingEligibilityVariancesForAdjustment(_ items: [RollingEligibilityVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePrimaryFollowUpAdjustmentsFromVariance(_ items: [RollingEligibilityVariance]) -> [PrimaryFollowUpAdjustment] {
        var out: [PrimaryFollowUpAdjustment] = []
        for item in items {
            let derived = newPrimaryFollowUpAdjustment(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyPrimaryFollowUpAdjustment(_ item: PrimaryFollowUpAdjustment) -> String {
        return classifyEligibilityEstimate(item.projectedValue())
    }
}
