import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceSegmentsForReview(_ items: [RemittanceSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func derivePendingClaimReviewsFromSegment(_ items: [RemittanceSegment]) -> [PendingClaimReview] {
        var out: [PendingClaimReview] = []
        for item in items {
            let derived = newPendingClaimReview(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPendingClaimReview(_ item: PendingClaimReview) -> String {
        return remittanceReservationBucket(item.weightedTotal())
    }
}
