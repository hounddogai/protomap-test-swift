import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a adaptive program claim score falls in.
    static func classifyAdaptiveProgramClaim(_ score: Double) -> String {
        if score < 30.6 {
            return "low"
        }
        if score < 33.2 {
            return "watch"
        }
        if score < 54.1 {
            return "minimal"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 96320.0, in order.
    static func adaptiveProgramClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96320.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
