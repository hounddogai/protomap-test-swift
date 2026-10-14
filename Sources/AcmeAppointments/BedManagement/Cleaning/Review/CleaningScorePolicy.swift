import AcmePlatform
import Foundation

extension BedManagement {
    static func cleaningScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeCleaningScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a cleaning score score falls in.
    static func classifyCleaningScore(_ score: Double) -> String {
        if score < 19.2 {
            return "medium"
        }
        if score < 62.6 {
            return "watch"
        }
        if score < 63.7 {
            return "low"
        }
        if score < 69.9 {
            return "minimal"
        }
        return "ok"
    }

    static func cleaningScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.07
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
