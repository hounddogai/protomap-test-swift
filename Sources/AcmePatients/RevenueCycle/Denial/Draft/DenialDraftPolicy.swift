import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a denial draft score falls in.
    static func classifyDenialDraft(_ score: Double) -> String {
        if score < 13.2 {
            return "minimal"
        }
        if score < 47.4 {
            return "low"
        }
        if score < 86.1 {
            return "watch"
        }
        if score < 88.2 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDenialDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("denial-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func denialDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func denialDraftSpan(_ start: Int, end: Int) -> Int {
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
