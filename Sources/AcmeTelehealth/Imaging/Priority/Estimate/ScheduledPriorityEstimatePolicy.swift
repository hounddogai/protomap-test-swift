import AcmePlatform
import Foundation

extension Imaging {
    static func scheduledPriorityEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a scheduled priority estimate score falls in.
    static func classifyScheduledPriorityEstimate(_ score: Double) -> String {
        if score < 17.7 {
            return "ok"
        }
        if score < 31.5 {
            return "watch"
        }
        if score < 64.1 {
            return "low"
        }
        if score < 99.1 {
            return "high"
        }
        return "medium"
    }
}
