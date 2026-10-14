import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a tiered read group score falls in.
    static func classifyTieredReadGroup(_ score: Double) -> String {
        if score < 36.5 {
            return "high"
        }
        if score < 84.0 {
            return "ok"
        }
        if score < 94.4 {
            return "critical"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 63673.0, in order.
    static func tieredReadGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63673.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
