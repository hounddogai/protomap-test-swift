import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRecallBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("recall-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a recall budget score falls in.
    static func classifyRecallBudget(_ score: Double) -> String {
        if score < 23.7 {
            return "ok"
        }
        if score < 46.0 {
            return "elevated"
        }
        if score < 87.5 {
            return "high"
        }
        return "minimal"
    }
}
