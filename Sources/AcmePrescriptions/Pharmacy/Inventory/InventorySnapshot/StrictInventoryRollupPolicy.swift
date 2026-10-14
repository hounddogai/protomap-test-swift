import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeStrictInventoryRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictInventoryRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func strictInventoryRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a strict inventory rollup score falls in.
    static func classifyStrictInventoryRollup(_ score: Double) -> String {
        if score < 18.9 {
            return "minimal"
        }
        if score < 20.7 {
            return "high"
        }
        return "elevated"
    }
}
