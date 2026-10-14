import AcmePlatform
import Foundation

extension CareManagement {
    static func goalBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func goalBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a goal batch score falls in.
    static func classifyGoalBatch(_ score: Double) -> String {
        if score < 23.0 {
            return "high"
        }
        if score < 29.0 {
            return "elevated"
        }
        if score < 86.6 {
            return "critical"
        }
        if score < 87.1 {
            return "ok"
        }
        return "watch"
    }

    static func mergeGoalBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
