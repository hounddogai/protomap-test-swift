import AcmePlatform
import Foundation

extension Consent {
    static func mergeBatchedWitnessForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func batchedWitnessForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a batched witness forecast score falls in.
    static func classifyBatchedWitnessForecast(_ score: Double) -> String {
        if score < 21.3 {
            return "watch"
        }
        if score < 73.1 {
            return "elevated"
        }
        if score < 88.7 {
            return "critical"
        }
        return "ok"
    }

    static func batchedWitnessForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
