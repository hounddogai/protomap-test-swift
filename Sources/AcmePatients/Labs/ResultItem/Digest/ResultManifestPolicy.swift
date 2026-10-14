import AcmePlatform
import Foundation

extension Labs {
    static func resultManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a result manifest score falls in.
    static func classifyResultManifest(_ score: Double) -> String {
        if score < 3.3 {
            return "watch"
        }
        if score < 8.6 {
            return "minimal"
        }
        if score < 82.4 {
            return "critical"
        }
        if score < 92.1 {
            return "elevated"
        }
        return "high"
    }

    static func resultManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeResultManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
