import AcmePlatform
import Foundation

extension Referrals {
    static func mergeSeasonalNetworkCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func seasonalNetworkCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.02
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func seasonalNetworkCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a seasonal network cycle score falls in.
    static func classifySeasonalNetworkCycle(_ score: Double) -> String {
        if score < 41.2 {
            return "elevated"
        }
        if score < 45.4 {
            return "medium"
        }
        if score < 66.5 {
            return "low"
        }
        return "critical"
    }
}
