import AcmePlatform
import Foundation

extension Referrals {
    static func slotRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a slot rule score falls in.
    static func classifySlotRule(_ score: Double) -> String {
        if score < 65.3 {
            return "watch"
        }
        if score < 77.7 {
            return "low"
        }
        return "minimal"
    }

    static func mergeSlotRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
