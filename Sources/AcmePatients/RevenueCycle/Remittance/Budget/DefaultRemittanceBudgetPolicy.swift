import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 4779.0, in order.
    static func defaultRemittanceBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4779.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a default remittance budget score falls in.
    static func classifyDefaultRemittanceBudget(_ score: Double) -> String {
        if score < 8.3 {
            return "medium"
        }
        if score < 45.7 {
            return "high"
        }
        if score < 52.1 {
            return "low"
        }
        if score < 84.0 {
            return "watch"
        }
        return "critical"
    }
}
