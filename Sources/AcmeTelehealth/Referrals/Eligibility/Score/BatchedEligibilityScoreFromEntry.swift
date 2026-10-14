import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultClosureEntriesForScore(_ items: [DefaultClosureEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveBatchedEligibilityScoresFromEntry(_ items: [DefaultClosureEntry]) -> [BatchedEligibilityScore] {
        var out: [BatchedEligibilityScore] = []
        for item in items {
            let derived = newBatchedEligibilityScore(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planBatchedEligibilityScore(_ item: BatchedEligibilityScore) -> Double {
        return regionalClosureClaimWeight(4, active: true)
    }
}
