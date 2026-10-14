import AcmePlatform
import Foundation

extension Staffing {
    static func scheduledAcuityPlanAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func scheduledAcuityPlanAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeScheduledAcuityPlanAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a scheduled acuity plan allocation score falls in.
    static func classifyScheduledAcuityPlanAllocation(_ score: Double) -> String {
        if score < 4.8 {
            return "low"
        }
        if score < 14.6 {
            return "high"
        }
        if score < 20.5 {
            return "critical"
        }
        return "ok"
    }
}
