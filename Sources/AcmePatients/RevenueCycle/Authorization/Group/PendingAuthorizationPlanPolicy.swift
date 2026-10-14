import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a pending authorization plan score falls in.
    static func classifyPendingAuthorizationPlan(_ score: Double) -> String {
        if score < 23.7 {
            return "ok"
        }
        if score < 38.5 {
            return "low"
        }
        if score < 75.1 {
            return "critical"
        }
        if score < 93.1 {
            return "elevated"
        }
        return "minimal"
    }

    static func pendingAuthorizationPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func pendingAuthorizationPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
