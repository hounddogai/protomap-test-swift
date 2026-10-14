import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpSegmentsForAgreement(_ items: [FollowUpSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveBatchedSlotAgreementsFromSegment(_ items: [FollowUpSegment]) -> [BatchedSlotAgreement] {
        var out: [BatchedSlotAgreement] = []
        for item in items {
            let derived = newBatchedSlotAgreement(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeBatchedSlotAgreement(_ item: BatchedSlotAgreement) -> Double {
        return fallbackFollowUpCycleWeight(7, active: true)
    }
}
