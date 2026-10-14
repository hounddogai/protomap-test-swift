import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultChargeMappingsForMilestone(_ items: [DefaultChargeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveBatchedDenialMilestonesFromMapping(_ items: [DefaultChargeMapping]) -> [BatchedDenialMilestone] {
        var out: [BatchedDenialMilestone] = []
        for item in items {
            let derived = newBatchedDenialMilestone(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyBatchedDenialMilestone(_ item: BatchedDenialMilestone) -> String {
        return globalChargeReviewBucket(item.adjustedTotal())
    }
}
