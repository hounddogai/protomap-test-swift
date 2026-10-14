import AcmePlatform
import Foundation

extension Consent {
    static func proxyMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProxyMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("proxy-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 40037.0, in order.
    static func proxyMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40037.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a proxy metric score falls in.
    static func classifyProxyMetric(_ score: Double) -> String {
        if score < 35.3 {
            return "critical"
        }
        if score < 55.1 {
            return "low"
        }
        if score < 61.9 {
            return "high"
        }
        if score < 77.9 {
            return "medium"
        }
        return "ok"
    }
}
