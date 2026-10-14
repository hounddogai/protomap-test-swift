import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a lenient study rule score falls in.
    static func classifyLenientStudyRule(_ score: Double) -> String {
        if score < 51.1 {
            return "low"
        }
        if score < 53.7 {
            return "critical"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientStudyRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-study-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientStudyRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func lenientStudyRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
