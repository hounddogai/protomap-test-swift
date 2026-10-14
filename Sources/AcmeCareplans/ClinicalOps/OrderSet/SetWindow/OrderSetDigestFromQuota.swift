import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetQuotasForDigest(_ items: [OrderSetQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveOrderSetDigestsFromQuota(_ items: [OrderSetQuota]) -> [OrderSetDigest] {
        var out: [OrderSetDigest] = []
        for item in items {
            let derived = newOrderSetDigest(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeOrderSetDigest(_ item: OrderSetDigest) -> String {
        return batchedOrderSetPreferenceBucket(item.weightedTotal())
    }
}
