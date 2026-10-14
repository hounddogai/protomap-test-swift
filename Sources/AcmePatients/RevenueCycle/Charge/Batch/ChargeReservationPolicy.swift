import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 22384.0, in order.
    static func chargeReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22384.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a charge reservation score falls in.
    static func classifyChargeReservation(_ score: Double) -> String {
        if score < 1.3 {
            return "elevated"
        }
        if score < 16.5 {
            return "minimal"
        }
        if score < 53.6 {
            return "high"
        }
        return "ok"
    }

    static func mergeChargeReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
