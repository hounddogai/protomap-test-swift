import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a closure plan score falls in.
    static func classifyClosurePlan(_ score: Double) -> String {
        if score < 41.1 {
            return "watch"
        }
        if score < 59.0 {
            return "ok"
        }
        if score < 72.9 {
            return "medium"
        }
        return "critical"
    }

    static func closurePlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeClosurePlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
