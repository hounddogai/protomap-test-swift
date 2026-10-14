import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a legacy interaction forecast score falls in.
    static func classifyLegacyInteractionForecast(_ score: Double) -> String {
        if score < 55.9 {
            return "medium"
        }
        if score < 98.4 {
            return "elevated"
        }
        return "critical"
    }

    static func legacyInteractionForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func legacyInteractionForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func legacyInteractionForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
