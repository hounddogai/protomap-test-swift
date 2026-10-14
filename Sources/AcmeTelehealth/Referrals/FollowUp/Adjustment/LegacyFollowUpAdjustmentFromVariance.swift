import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeBatchedEligibilityVariancesForAdjustment(_ items: [BatchedEligibilityVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLegacyFollowUpAdjustmentsFromVariance(_ items: [BatchedEligibilityVariance]) -> [LegacyFollowUpAdjustment] {
        var out: [LegacyFollowUpAdjustment] = []
        for item in items {
            let derived = newLegacyFollowUpAdjustment(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectLegacyFollowUpAdjustment(_ item: LegacyFollowUpAdjustment) -> Double {
        return batchedEligibilityVarianceWeight(4, active: true)
    }
}
