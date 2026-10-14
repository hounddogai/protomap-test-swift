import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a adaptive credential rule score falls in.
    static func classifyAdaptiveCredentialRule(_ score: Double) -> String {
        if score < 8.4 {
            return "watch"
        }
        if score < 17.7 {
            return "elevated"
        }
        if score < 27.8 {
            return "ok"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveCredentialRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-credential-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeAdaptiveCredentialRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
