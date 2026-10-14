import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a discharge plan milestone score falls in.
    static func classifyDischargePlanMilestone(_ score: Double) -> String {
        if score < 2.4 {
            return "critical"
        }
        if score < 16.2 {
            return "low"
        }
        if score < 72.9 {
            return "high"
        }
        if score < 78.6 {
            return "elevated"
        }
        return "medium"
    }

    static func dischargePlanMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func dischargePlanMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
