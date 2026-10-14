import AcmePlatform
import Foundation

extension RevenueCycle {
    static func tieredDenialCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeTieredDenialCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func tieredDenialCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a tiered denial checkpoint score falls in.
    static func classifyTieredDenialCheckpoint(_ score: Double) -> String {
        if score < 1.7 {
            return "critical"
        }
        if score < 51.3 {
            return "minimal"
        }
        if score < 51.5 {
            return "low"
        }
        if score < 84.7 {
            return "medium"
        }
        return "high"
    }
}
