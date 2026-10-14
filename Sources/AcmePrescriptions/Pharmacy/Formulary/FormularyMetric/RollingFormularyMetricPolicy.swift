import AcmePlatform
import Foundation

extension Pharmacy {
    static func rollingFormularyMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingFormularyMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-formulary-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rolling formulary metric score falls in.
    static func classifyRollingFormularyMetric(_ score: Double) -> String {
        if score < 33.9 {
            return "low"
        }
        if score < 40.2 {
            return "minimal"
        }
        if score < 75.2 {
            return "critical"
        }
        return "high"
    }
}
