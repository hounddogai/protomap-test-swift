import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientReferenceRangeDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-reference-range-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientReferenceRangeDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func lenientReferenceRangeDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a lenient reference range draft score falls in.
    static func classifyLenientReferenceRangeDraft(_ score: Double) -> String {
        if score < 23.3 {
            return "watch"
        }
        if score < 34.1 {
            return "critical"
        }
        if score < 62.2 {
            return "ok"
        }
        if score < 63.2 {
            return "medium"
        }
        return "elevated"
    }
}
