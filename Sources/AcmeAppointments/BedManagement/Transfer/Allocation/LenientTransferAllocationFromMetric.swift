import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientCleaningMetricsForAllocation(_ items: [LenientCleaningMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLenientTransferAllocationsFromMetric(_ items: [LenientCleaningMetric]) -> [LenientTransferAllocation] {
        var out: [LenientTransferAllocation] = []
        for item in items {
            let derived = newLenientTransferAllocation(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleLenientTransferAllocation(_ item: LenientTransferAllocation) -> String {
        return normalizePendingCleaningReservationCode(item.code)
    }
}
