import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a courier group score falls in.
    static func classifyCourierGroup(_ score: Double) -> String {
        if score < 16.3 {
            return "low"
        }
        if score < 23.7 {
            return "critical"
        }
        if score < 26.1 {
            return "high"
        }
        return "watch"
    }

    static func courierGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeCourierGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
