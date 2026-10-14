import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpBatchesForCycle(_ items: [FollowUpBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveLegacyClosureCyclesFromBatch(_ items: [FollowUpBatch]) -> [LegacyClosureCycle] {
        var out: [LegacyClosureCycle] = []
        for item in items {
            let derived = newLegacyClosureCycle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileLegacyClosureCycle(_ item: LegacyClosureCycle) -> String {
        return classifyFollowUpReview(item.projectedVolume())
    }
}
