import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a authorization digest score falls in.
    static func classifyAuthorizationDigest(_ score: Double) -> String {
        if score < 25.3 {
            return "critical"
        }
        if score < 87.2 {
            return "medium"
        }
        if score < 99.7 {
            return "minimal"
        }
        return "low"
    }

    static func authorizationDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAuthorizationDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("authorization-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func authorizationDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
