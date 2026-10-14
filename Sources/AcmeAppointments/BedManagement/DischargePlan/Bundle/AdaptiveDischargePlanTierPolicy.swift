import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveDischargePlanTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a adaptive discharge plan tier score falls in.
    static func classifyAdaptiveDischargePlanTier(_ score: Double) -> String {
        if score < 46.4 {
            return "low"
        }
        if score < 63.8 {
            return "watch"
        }
        if score < 79.5 {
            return "high"
        }
        if score < 94.3 {
            return "medium"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 91223.0, in order.
    static func adaptiveDischargePlanTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91223.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
