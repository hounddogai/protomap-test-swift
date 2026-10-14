import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeAuthorizationReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a authorization reservation score falls in.
    static func classifyAuthorizationReservation(_ score: Double) -> String {
        if score < 15.7 {
            return "medium"
        }
        if score < 41.3 {
            return "high"
        }
        if score < 89.0 {
            return "critical"
        }
        if score < 98.0 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 42932.0, in order.
    static func authorizationReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42932.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func authorizationReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.03
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
