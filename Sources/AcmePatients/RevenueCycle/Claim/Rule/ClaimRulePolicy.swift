import AcmePlatform
import Foundation

extension RevenueCycle {
    static func claimRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a claim rule score falls in.
    static func classifyClaimRule(_ score: Double) -> String {
        if score < 25.5 {
            return "low"
        }
        if score < 31.4 {
            return "elevated"
        }
        if score < 66.2 {
            return "critical"
        }
        if score < 91.0 {
            return "ok"
        }
        return "high"
    }
}
