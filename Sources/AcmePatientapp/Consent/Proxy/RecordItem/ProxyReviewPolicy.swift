import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a proxy review score falls in.
    static func classifyProxyReview(_ score: Double) -> String {
        if score < 23.3 {
            return "low"
        }
        if score < 72.8 {
            return "elevated"
        }
        if score < 76.2 {
            return "critical"
        }
        if score < 93.5 {
            return "watch"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProxyReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("proxy-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func proxyReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
