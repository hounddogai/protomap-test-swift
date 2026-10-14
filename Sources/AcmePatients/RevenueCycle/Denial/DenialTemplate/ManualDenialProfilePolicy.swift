import AcmePlatform
import Foundation

extension RevenueCycle {
    static func manualDenialProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 30035.0, in order.
    static func manualDenialProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30035.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual denial profile score falls in.
    static func classifyManualDenialProfile(_ score: Double) -> String {
        if score < 13.9 {
            return "medium"
        }
        if score < 33.1 {
            return "minimal"
        }
        if score < 72.7 {
            return "low"
        }
        if score < 89.0 {
            return "watch"
        }
        return "elevated"
    }

    static func manualDenialProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
