import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityRulesForReservation(_ items: [PriorityRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func derivePriorityReservationsFromRule(_ items: [PriorityRule]) -> [PriorityReservation] {
        var out: [PriorityReservation] = []
        for item in items {
            let derived = newPriorityReservation(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizePriorityReservation(_ item: PriorityReservation) -> Double {
        return priorityThresholdWeight(8, active: true)
    }
}
