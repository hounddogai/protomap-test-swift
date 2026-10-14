import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 24715.0, in order.
    static func riskScoreBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24715.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a risk score bundle score falls in.
    static func classifyRiskScoreBundle(_ score: Double) -> String {
        if score < 25.8 {
            return "low"
        }
        if score < 45.5 {
            return "elevated"
        }
        if score < 56.2 {
            return "medium"
        }
        if score < 95.2 {
            return "watch"
        }
        return "high"
    }

    static func riskScoreBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
