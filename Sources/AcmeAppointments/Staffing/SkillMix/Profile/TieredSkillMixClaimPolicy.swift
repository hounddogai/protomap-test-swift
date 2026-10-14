import AcmePlatform
import Foundation

extension Staffing {
    static func tieredSkillMixClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a tiered skill mix claim score falls in.
    static func classifyTieredSkillMixClaim(_ score: Double) -> String {
        if score < 3.4 {
            return "medium"
        }
        if score < 35.1 {
            return "ok"
        }
        if score < 35.3 {
            return "high"
        }
        return "elevated"
    }
}
