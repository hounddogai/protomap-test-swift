import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a network policy score falls in.
    static func classifyNetworkPolicy(_ score: Double) -> String {
        if score < 53.4 {
            return "critical"
        }
        if score < 57.3 {
            return "minimal"
        }
        if score < 99.1 {
            return "ok"
        }
        return "medium"
    }

    static func mergeNetworkPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func networkPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
