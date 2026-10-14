import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeTieredIsolationTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func tieredIsolationTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func tieredIsolationTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a tiered isolation target score falls in.
    static func classifyTieredIsolationTarget(_ score: Double) -> String {
        if score < 50.9 {
            return "elevated"
        }
        if score < 61.5 {
            return "watch"
        }
        if score < 84.4 {
            return "minimal"
        }
        return "critical"
    }
}
