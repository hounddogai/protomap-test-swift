import AcmePlatform
import Foundation

extension Pharmacy {
    static func lenientSubstitutionClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func lenientSubstitutionClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.21
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientSubstitutionClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-substitution-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a lenient substitution claim score falls in.
    static func classifyLenientSubstitutionClaim(_ score: Double) -> String {
        if score < 58.3 {
            return "medium"
        }
        if score < 68.1 {
            return "elevated"
        }
        if score < 68.8 {
            return "low"
        }
        return "watch"
    }
}
