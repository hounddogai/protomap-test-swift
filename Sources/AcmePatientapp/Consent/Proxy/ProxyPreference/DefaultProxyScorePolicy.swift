import AcmePlatform
import Foundation

extension Consent {
    static func defaultProxyScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a default proxy score score falls in.
    static func classifyDefaultProxyScore(_ score: Double) -> String {
        if score < 13.3 {
            return "elevated"
        }
        if score < 60.1 {
            return "watch"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultProxyScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-proxy-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultProxyScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
