import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallReservationsForAllocation(_ items: [RecallReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveStrictFormularyAllocationsFromReservation(_ items: [RecallReservation]) -> [StrictFormularyAllocation] {
        var out: [StrictFormularyAllocation] = []
        for item in items {
            let derived = newStrictFormularyAllocation(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankStrictFormularyAllocation(_ item: StrictFormularyAllocation) -> String {
        return recallDraftBucket(item.effectiveExposure())
    }
}
