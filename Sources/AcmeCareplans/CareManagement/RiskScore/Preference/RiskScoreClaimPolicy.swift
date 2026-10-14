import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 23272.0, in order.
    static func riskScoreClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23272.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a risk score claim score falls in.
    static func classifyRiskScoreClaim(_ score: Double) -> String {
        if score < 1.7 {
            return "ok"
        }
        if score < 6.4 {
            return "medium"
        }
        if score < 20.9 {
            return "watch"
        }
        if score < 91.6 {
            return "critical"
        }
        return "high"
    }
}
