import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedCourierAllocationsForReservation(_ items: [WeightedCourierAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveDefaultAccessionReservationsFromAllocation(_ items: [WeightedCourierAllocation]) -> [DefaultAccessionReservation] {
        var out: [DefaultAccessionReservation] = []
        for item in items {
            let derived = newDefaultAccessionReservation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignDefaultAccessionReservation(_ item: DefaultAccessionReservation) -> Double {
        return fallbackCourierCycleWeight(7, active: true)
    }
}
