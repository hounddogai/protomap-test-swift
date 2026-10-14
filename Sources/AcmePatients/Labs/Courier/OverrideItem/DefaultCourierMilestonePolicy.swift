import AcmePlatform
import Foundation

extension Labs {
    static func defaultCourierMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeDefaultCourierMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default courier milestone score falls in.
    static func classifyDefaultCourierMilestone(_ score: Double) -> String {
        if score < 4.6 {
            return "minimal"
        }
        if score < 71.2 {
            return "watch"
        }
        if score < 82.9 {
            return "critical"
        }
        return "elevated"
    }
}
