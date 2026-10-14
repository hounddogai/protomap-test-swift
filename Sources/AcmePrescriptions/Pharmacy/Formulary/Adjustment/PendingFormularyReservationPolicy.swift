import AcmePlatform
import Foundation

extension Pharmacy {
    static func pendingFormularyReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a pending formulary reservation score falls in.
    static func classifyPendingFormularyReservation(_ score: Double) -> String {
        if score < 47.4 {
            return "ok"
        }
        if score < 82.2 {
            return "high"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 22481.0, in order.
    static func pendingFormularyReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22481.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingFormularyReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
