import AcmePlatform
import Foundation

extension Referrals {
    static func mergeScheduledFollowUpManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledFollowUpManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-follow-up-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a scheduled follow up manifest score falls in.
    static func classifyScheduledFollowUpManifest(_ score: Double) -> String {
        if score < 39.4 {
            return "watch"
        }
        if score < 46.1 {
            return "ok"
        }
        return "low"
    }

    static func scheduledFollowUpManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
