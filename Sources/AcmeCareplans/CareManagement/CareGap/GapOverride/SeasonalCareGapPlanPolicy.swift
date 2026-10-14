import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a seasonal care gap plan score falls in.
    static func classifySeasonalCareGapPlan(_ score: Double) -> String {
        if score < 14.6 {
            return "ok"
        }
        if score < 48.0 {
            return "medium"
        }
        if score < 69.8 {
            return "high"
        }
        if score < 76.0 {
            return "critical"
        }
        return "low"
    }

    static func seasonalCareGapPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func seasonalCareGapPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func mergeSeasonalCareGapPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
