import AcmePlatform
import Foundation

extension Labs {
    static func rollingPanelPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func rollingPanelPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a rolling panel preference score falls in.
    static func classifyRollingPanelPreference(_ score: Double) -> String {
        if score < 25.1 {
            return "critical"
        }
        if score < 75.9 {
            return "low"
        }
        if score < 90.0 {
            return "elevated"
        }
        if score < 94.2 {
            return "medium"
        }
        return "watch"
    }

    static func mergeRollingPanelPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
