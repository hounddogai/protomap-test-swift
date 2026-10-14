import AcmePlatform
import Foundation

extension Consent {
    static func fallbackProxyThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackProxyThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-proxy-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 86350.0, in order.
    static func fallbackProxyThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 86350.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a fallback proxy threshold score falls in.
    static func classifyFallbackProxyThreshold(_ score: Double) -> String {
        if score < 47.6 {
            return "ok"
        }
        if score < 92.0 {
            return "elevated"
        }
        if score < 96.2 {
            return "low"
        }
        if score < 99.3 {
            return "minimal"
        }
        return "critical"
    }
}
