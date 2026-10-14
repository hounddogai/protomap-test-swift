import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 38869.0, in order.
    static func rollingGoalCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38869.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rolling goal cycle score falls in.
    static func classifyRollingGoalCycle(_ score: Double) -> String {
        if score < 23.9 {
            return "low"
        }
        if score < 26.8 {
            return "ok"
        }
        if score < 61.6 {
            return "high"
        }
        if score < 66.6 {
            return "minimal"
        }
        return "elevated"
    }
}
