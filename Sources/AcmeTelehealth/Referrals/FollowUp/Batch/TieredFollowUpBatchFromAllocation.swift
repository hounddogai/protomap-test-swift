import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityAllocationsForBatch(_ items: [EligibilityAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveTieredFollowUpBatchesFromAllocation(_ items: [EligibilityAllocation]) -> [TieredFollowUpBatch] {
        var out: [TieredFollowUpBatch] = []
        for item in items {
            let derived = newTieredFollowUpBatch(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateTieredFollowUpBatch(_ item: TieredFollowUpBatch) -> String {
        return eligibilityAgreementBucket(item.projectedLoad())
    }
}
