import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a weighted referral segment score falls in.
    static func classifyWeightedReferralSegment(_ score: Double) -> String {
        if score < 9.8 {
            return "low"
        }
        if score < 13.7 {
            return "ok"
        }
        if score < 36.8 {
            return "high"
        }
        if score < 37.4 {
            return "critical"
        }
        return "watch"
    }

    static func mergeWeightedReferralSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedReferralSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-referral-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
