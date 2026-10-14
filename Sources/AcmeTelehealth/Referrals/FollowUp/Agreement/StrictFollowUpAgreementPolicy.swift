import AcmePlatform
import Foundation

extension Referrals {
    static func strictFollowUpAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a strict follow up agreement score falls in.
    static func classifyStrictFollowUpAgreement(_ score: Double) -> String {
        if score < 16.2 {
            return "elevated"
        }
        if score < 17.5 {
            return "minimal"
        }
        if score < 65.7 {
            return "critical"
        }
        return "low"
    }

    static func mergeStrictFollowUpAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
