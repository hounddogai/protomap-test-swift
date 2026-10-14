import AcmePlatform
import Foundation

extension Labs {
    static func resultThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a result threshold score falls in.
    static func classifyResultThreshold(_ score: Double) -> String {
        if score < 12.7 {
            return "medium"
        }
        if score < 16.6 {
            return "high"
        }
        if score < 32.2 {
            return "ok"
        }
        if score < 36.8 {
            return "critical"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 60888.0, in order.
    static func resultThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60888.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
