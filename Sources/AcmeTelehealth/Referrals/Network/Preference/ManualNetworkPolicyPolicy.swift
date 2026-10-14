import AcmePlatform
import Foundation

extension Referrals {
    static func mergeManualNetworkPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a manual network policy score falls in.
    static func classifyManualNetworkPolicy(_ score: Double) -> String {
        if score < 53.1 {
            return "watch"
        }
        if score < 70.3 {
            return "minimal"
        }
        return "ok"
    }
}
