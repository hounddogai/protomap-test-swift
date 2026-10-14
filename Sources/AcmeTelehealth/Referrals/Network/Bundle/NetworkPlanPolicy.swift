import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a network plan score falls in.
    static func classifyNetworkPlan(_ score: Double) -> String {
        if score < 6.0 {
            return "critical"
        }
        if score < 21.7 {
            return "medium"
        }
        if score < 27.2 {
            return "elevated"
        }
        if score < 52.3 {
            return "watch"
        }
        return "ok"
    }

    static func mergeNetworkPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
