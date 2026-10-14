import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrimaryPriorityThresholdsForReservation(_ items: [PrimaryPriorityThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveCappedPriorityReservationsFromThreshold(_ items: [PrimaryPriorityThreshold]) -> [CappedPriorityReservation] {
        var out: [CappedPriorityReservation] = []
        for item in items {
            let derived = newCappedPriorityReservation(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyCappedPriorityReservation(_ item: CappedPriorityReservation) -> String {
        return normalizePrimaryPriorityThresholdCode(item.code)
    }
}
