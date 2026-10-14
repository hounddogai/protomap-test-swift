import AcmePlatform
import Foundation

extension RevenueCycle {
    static func remittanceEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a remittance entry score falls in.
    static func classifyRemittanceEntry(_ score: Double) -> String {
        if score < 15.0 {
            return "medium"
        }
        if score < 19.2 {
            return "critical"
        }
        if score < 27.6 {
            return "high"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 94238.0, in order.
    static func remittanceEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94238.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func remittanceEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
