import AcmePlatform
import Foundation

extension Referrals {
    static func mergeEligibilityExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityException() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a eligibility exception score falls in.
    static func classifyEligibilityException(_ score: Double) -> String {
        if score < 1.8 {
            return "elevated"
        }
        if score < 4.2 {
            return "medium"
        }
        if score < 65.0 {
            return "minimal"
        }
        return "low"
    }
}
