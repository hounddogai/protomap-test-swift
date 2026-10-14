import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeGoalTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a goal tier score falls in.
    static func classifyGoalTier(_ score: Double) -> String {
        if score < 17.2 {
            return "high"
        }
        if score < 25.8 {
            return "elevated"
        }
        if score < 59.0 {
            return "low"
        }
        if score < 81.8 {
            return "watch"
        }
        return "ok"
    }

    static func goalTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func goalTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
