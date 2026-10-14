import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedInventoryPoliciesForRequest(_ items: [BatchedInventoryPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingRecallRequestsFromPolicy(_ items: [BatchedInventoryPolicy]) -> [PendingRecallRequest] {
        var out: [PendingRecallRequest] = []
        for item in items {
            let derived = newPendingRecallRequest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPendingRecallRequest(_ item: PendingRecallRequest) -> String {
        return normalizeScheduledInventoryWindowCode(item.code)
    }
}
