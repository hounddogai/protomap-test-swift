import AcmePlatform
import Foundation

extension Imaging {
    static func priorityThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a priority threshold score falls in.
    static func classifyPriorityThreshold(_ score: Double) -> String {
        if score < 4.2 {
            return "low"
        }
        if score < 31.1 {
            return "ok"
        }
        if score < 79.7 {
            return "high"
        }
        return "elevated"
    }
}
