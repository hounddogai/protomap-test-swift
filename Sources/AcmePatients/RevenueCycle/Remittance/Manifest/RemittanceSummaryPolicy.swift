import AcmePlatform
import Foundation

extension RevenueCycle {
    static func remittanceSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 78890.0, in order.
    static func remittanceSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78890.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a remittance summary score falls in.
    static func classifyRemittanceSummary(_ score: Double) -> String {
        if score < 9.2 {
            return "low"
        }
        if score < 23.1 {
            return "minimal"
        }
        if score < 47.1 {
            return "watch"
        }
        if score < 71.5 {
            return "critical"
        }
        return "medium"
    }
}
