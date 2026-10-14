import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityRequestsForScore(_ items: [EligibilityRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedEligibilityScoresFromRequest(_ items: [EligibilityRequest]) -> [BatchedEligibilityScore] {
        var out: [BatchedEligibilityScore] = []
        for item in items {
            let derived = newBatchedEligibilityScore(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleBatchedEligibilityScore(_ item: BatchedEligibilityScore) -> String {
        return classifySeasonalEligibilityRecord(item.effectiveExposure())
    }
}
