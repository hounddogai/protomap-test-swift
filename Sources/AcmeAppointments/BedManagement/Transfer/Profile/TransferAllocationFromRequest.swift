import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedTransferRequestsForAllocation(_ items: [WeightedTransferRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveTransferAllocationsFromRequest(_ items: [WeightedTransferRequest]) -> [TransferAllocation] {
        var out: [TransferAllocation] = []
        for item in items {
            let derived = newTransferAllocation(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectTransferAllocation(_ item: TransferAllocation) -> String {
        return normalizeManualTransferEstimateCode(item.code)
    }
}
