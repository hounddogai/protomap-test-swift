import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a read override score falls in.
    static func classifyReadOverride(_ score: Double) -> String {
        if score < 12.6 {
            return "high"
        }
        if score < 87.0 {
            return "elevated"
        }
        return "low"
    }

    static func readOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeReadOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func readOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
