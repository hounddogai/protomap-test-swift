import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 81618.0, in order.
    static func careGapReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 81618.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a care gap reservation score falls in.
    static func classifyCareGapReservation(_ score: Double) -> String {
        if score < 12.4 {
            return "minimal"
        }
        if score < 64.2 {
            return "critical"
        }
        if score < 90.2 {
            return "watch"
        }
        return "high"
    }

    static func careGapReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
