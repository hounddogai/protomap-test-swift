import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a referral claim score falls in.
    static func classifyReferralClaim(_ score: Double) -> String {
        if score < 16.8 {
            return "ok"
        }
        if score < 36.7 {
            return "elevated"
        }
        if score < 59.2 {
            return "low"
        }
        if score < 98.2 {
            return "medium"
        }
        return "high"
    }

    static func referralClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func referralClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func mergeReferralClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
