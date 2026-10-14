import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 93188.0, in order.
    static func fallbackRiskScoreRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93188.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a fallback risk score rule score falls in.
    static func classifyFallbackRiskScoreRule(_ score: Double) -> String {
        if score < 44.4 {
            return "high"
        }
        if score < 59.3 {
            return "watch"
        }
        return "critical"
    }
}
