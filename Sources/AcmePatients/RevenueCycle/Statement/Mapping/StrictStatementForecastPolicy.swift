import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictStatementForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-statement-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a strict statement forecast score falls in.
    static func classifyStrictStatementForecast(_ score: Double) -> String {
        if score < 43.9 {
            return "medium"
        }
        if score < 56.5 {
            return "critical"
        }
        if score < 62.2 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 39682.0, in order.
    static func strictStatementForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39682.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
