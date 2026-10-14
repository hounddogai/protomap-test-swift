import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientRecallMilestonesForPolicy(_ items: [LenientRecallMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveBatchedSubstitutionPoliciesFromMilestone(_ items: [LenientRecallMilestone]) -> [BatchedSubstitutionPolicy] {
        var out: [BatchedSubstitutionPolicy] = []
        for item in items {
            let derived = newBatchedSubstitutionPolicy(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedSubstitutionPolicy(_ item: BatchedSubstitutionPolicy) -> String {
        return pendingRecallRollupBucket(item.weightedValue())
    }
}
