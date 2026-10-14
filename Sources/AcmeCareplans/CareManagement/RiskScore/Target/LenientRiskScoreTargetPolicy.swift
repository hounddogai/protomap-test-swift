import AcmePlatform
import Foundation

extension CareManagement {
    static func lenientRiskScoreTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a lenient risk score target score falls in.
    static func classifyLenientRiskScoreTarget(_ score: Double) -> String {
        if score < 8.3 {
            return "low"
        }
        if score < 74.7 {
            return "elevated"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 79199.0, in order.
    static func lenientRiskScoreTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79199.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientRiskScoreTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-risk-score-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
