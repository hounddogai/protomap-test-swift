import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictPriorityBudgetsForReservation(_ items: [StrictPriorityBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func derivePendingReadReservationsFromBudget(_ items: [StrictPriorityBudget]) -> [PendingReadReservation] {
        var out: [PendingReadReservation] = []
        for item in items {
            let derived = newPendingReadReservation(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func derivePendingReadReservation(_ item: PendingReadReservation) -> Double {
        return seasonalPriorityAgreementWeight(3, active: true)
    }
}
