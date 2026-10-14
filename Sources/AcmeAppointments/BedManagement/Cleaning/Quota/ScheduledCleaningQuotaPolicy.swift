import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a scheduled cleaning quota score falls in.
    static func classifyScheduledCleaningQuota(_ score: Double) -> String {
        if score < 1.6 {
            return "minimal"
        }
        if score < 14.0 {
            return "low"
        }
        if score < 15.7 {
            return "medium"
        }
        if score < 43.9 {
            return "watch"
        }
        return "critical"
    }

    static func scheduledCleaningQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func scheduledCleaningQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeScheduledCleaningQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
