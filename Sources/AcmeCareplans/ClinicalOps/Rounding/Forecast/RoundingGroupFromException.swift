import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeBatchedOrderSetExceptionsForGroup(_ items: [BatchedOrderSetException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRoundingGroupsFromException(_ items: [BatchedOrderSetException]) -> [RoundingGroup] {
        var out: [RoundingGroup] = []
        for item in items {
            let derived = newRoundingGroup(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRoundingGroup(_ item: RoundingGroup) -> String {
        return normalizePendingOrderSetGroupCode(item.code)
    }
}
