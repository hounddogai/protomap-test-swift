import AcmePlatform
import Foundation

extension Referrals {
    static func referralEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func referralEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeReferralEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a referral estimate score falls in.
    static func classifyReferralEstimate(_ score: Double) -> String {
        if score < 10.2 {
            return "ok"
        }
        if score < 97.4 {
            return "high"
        }
        if score < 99.4 {
            return "critical"
        }
        return "elevated"
    }
}
