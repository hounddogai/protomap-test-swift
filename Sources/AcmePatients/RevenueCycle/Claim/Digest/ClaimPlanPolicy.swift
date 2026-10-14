import AcmePlatform
import Foundation

extension RevenueCycle {
    static func claimPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a claim plan score falls in.
    static func classifyClaimPlan(_ score: Double) -> String {
        if score < 10.3 {
            return "low"
        }
        if score < 91.5 {
            return "high"
        }
        return "critical"
    }
}
