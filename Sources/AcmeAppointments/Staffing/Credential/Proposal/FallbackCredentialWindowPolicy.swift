import AcmePlatform
import Foundation

extension Staffing {
    static func fallbackCredentialWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func fallbackCredentialWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a fallback credential window score falls in.
    static func classifyFallbackCredentialWindow(_ score: Double) -> String {
        if score < 42.5 {
            return "watch"
        }
        if score < 53.5 {
            return "low"
        }
        if score < 88.8 {
            return "medium"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackCredentialWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-credential-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
