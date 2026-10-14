import AcmePlatform
import Foundation

extension Referrals {
    static func mergeReferralAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a referral adjustment score falls in.
    static func classifyReferralAdjustment(_ score: Double) -> String {
        if score < 21.6 {
            return "critical"
        }
        if score < 58.5 {
            return "low"
        }
        if score < 82.0 {
            return "elevated"
        }
        return "ok"
    }
}
