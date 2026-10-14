import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityReservationsForScore(_ items: [EligibilityReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveBatchedClosureScoresFromReservation(_ items: [EligibilityReservation]) -> [BatchedClosureScore] {
        var out: [BatchedClosureScore] = []
        for item in items {
            let derived = newBatchedClosureScore(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedClosureScore(_ item: BatchedClosureScore) -> Double {
        return eligibilityReservationWeight(4, active: true)
    }
}
