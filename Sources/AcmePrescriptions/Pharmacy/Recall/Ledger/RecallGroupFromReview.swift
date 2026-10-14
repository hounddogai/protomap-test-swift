import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryReviewsForGroup(_ items: [InventoryReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRecallGroupsFromReview(_ items: [InventoryReview]) -> [RecallGroup] {
        var out: [RecallGroup] = []
        for item in items {
            let derived = newRecallGroup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRecallGroup(_ item: RecallGroup) -> String {
        return classifyInventoryThreshold(item.projectedTotal())
    }
}
