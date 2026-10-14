import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation threshold score falls in.
    static func classifyRevocationThreshold(_ score: Double) -> String {
        if score < 59.5 {
            return "minimal"
        }
        if score < 73.8 {
            return "low"
        }
        if score < 75.5 {
            return "elevated"
        }
        if score < 93.1 {
            return "critical"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func revocationThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 90022.0, in order.
    static func revocationThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90022.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
