import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallQuotasForMilestone(_ items: [RecallQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveBatchedInteractionMilestonesFromQuota(_ items: [RecallQuota]) -> [BatchedInteractionMilestone] {
        var out: [BatchedInteractionMilestone] = []
        for item in items {
            let derived = newBatchedInteractionMilestone(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planBatchedInteractionMilestone(_ item: BatchedInteractionMilestone) -> String {
        return recallAllocationBucket(item.projectedExposure())
    }
}
