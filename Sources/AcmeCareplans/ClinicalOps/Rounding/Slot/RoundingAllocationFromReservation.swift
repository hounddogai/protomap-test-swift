import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetReservationsForAllocation(_ items: [OrderSetReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveRoundingAllocationsFromReservation(_ items: [OrderSetReservation]) -> [RoundingAllocation] {
        var out: [RoundingAllocation] = []
        for item in items {
            let derived = newRoundingAllocation(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchRoundingAllocation(_ item: RoundingAllocation) -> String {
        return normalizeOrderSetTargetCode(item.code)
    }
}
