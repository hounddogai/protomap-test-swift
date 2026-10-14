import AcmePlatform
import Foundation

extension RevenueCycle {
    static func strictClaimAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a strict claim allocation score falls in.
    static func classifyStrictClaimAllocation(_ score: Double) -> String {
        if score < 71.5 {
            return "ok"
        }
        if score < 71.8 {
            return "medium"
        }
        if score < 81.1 {
            return "low"
        }
        if score < 87.2 {
            return "elevated"
        }
        return "critical"
    }
}
