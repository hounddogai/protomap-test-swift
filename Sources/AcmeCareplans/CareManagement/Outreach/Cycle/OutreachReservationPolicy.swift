import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a outreach reservation score falls in.
    static func classifyOutreachReservation(_ score: Double) -> String {
        if score < 5.4 {
            return "ok"
        }
        if score < 11.1 {
            return "medium"
        }
        if score < 29.0 {
            return "low"
        }
        if score < 74.5 {
            return "watch"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 2251.0, in order.
    static func outreachReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2251.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
