import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackOvertimePolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-overtime-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackOvertimePolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 50575.0, in order.
    static func fallbackOvertimePolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50575.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a fallback overtime policy score falls in.
    static func classifyFallbackOvertimePolicy(_ score: Double) -> String {
        if score < 44.9 {
            return "low"
        }
        if score < 59.7 {
            return "critical"
        }
        if score < 97.8 {
            return "elevated"
        }
        return "medium"
    }
}
