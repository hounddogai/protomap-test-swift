import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a eligibility manifest score falls in.
    static func classifyEligibilityManifest(_ score: Double) -> String {
        if score < 21.0 {
            return "low"
        }
        if score < 45.0 {
            return "ok"
        }
        if score < 93.7 {
            return "medium"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeEligibilityManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
