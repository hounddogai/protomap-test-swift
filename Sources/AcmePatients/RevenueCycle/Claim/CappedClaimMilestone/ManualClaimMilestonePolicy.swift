import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a manual claim milestone score falls in.
    static func classifyManualClaimMilestone(_ score: Double) -> String {
        if score < 24.6 {
            return "medium"
        }
        if score < 30.5 {
            return "ok"
        }
        if score < 61.9 {
            return "watch"
        }
        return "elevated"
    }

    static func manualClaimMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
