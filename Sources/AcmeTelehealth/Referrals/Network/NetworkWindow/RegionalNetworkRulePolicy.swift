import AcmePlatform
import Foundation

extension Referrals {
    static func regionalNetworkRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a regional network rule score falls in.
    static func classifyRegionalNetworkRule(_ score: Double) -> String {
        if score < 4.3 {
            return "medium"
        }
        if score < 23.1 {
            return "critical"
        }
        return "high"
    }
}
