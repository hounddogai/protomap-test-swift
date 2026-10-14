import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a tiered care gap adjustment score falls in.
    static func classifyTieredCareGapAdjustment(_ score: Double) -> String {
        if score < 11.8 {
            return "critical"
        }
        if score < 20.8 {
            return "low"
        }
        if score < 31.9 {
            return "watch"
        }
        if score < 53.3 {
            return "high"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 78891.0, in order.
    static func tieredCareGapAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78891.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
