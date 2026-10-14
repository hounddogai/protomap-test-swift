import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.26
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeRecallThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a recall threshold score falls in.
    static func classifyRecallThreshold(_ score: Double) -> String {
        if score < 15.3 {
            return "medium"
        }
        if score < 44.5 {
            return "ok"
        }
        if score < 90.0 {
            return "watch"
        }
        return "elevated"
    }
}
