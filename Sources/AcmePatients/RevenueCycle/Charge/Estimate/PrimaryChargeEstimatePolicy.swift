import AcmePlatform
import Foundation

extension RevenueCycle {
    static func primaryChargeEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a primary charge estimate score falls in.
    static func classifyPrimaryChargeEstimate(_ score: Double) -> String {
        if score < 4.6 {
            return "ok"
        }
        if score < 4.7 {
            return "minimal"
        }
        if score < 19.4 {
            return "elevated"
        }
        if score < 94.1 {
            return "low"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 17670.0, in order.
    static func primaryChargeEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17670.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
