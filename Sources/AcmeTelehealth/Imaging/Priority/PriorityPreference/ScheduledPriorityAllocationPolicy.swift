import AcmePlatform
import Foundation

extension Imaging {
    static func scheduledPriorityAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a scheduled priority allocation score falls in.
    static func classifyScheduledPriorityAllocation(_ score: Double) -> String {
        if score < 20.3 {
            return "minimal"
        }
        if score < 63.6 {
            return "watch"
        }
        if score < 75.3 {
            return "medium"
        }
        if score < 84.5 {
            return "low"
        }
        return "high"
    }
}
