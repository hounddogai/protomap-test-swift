import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a result forecast score falls in.
    static func classifyResultForecast(_ score: Double) -> String {
        if score < 42.5 {
            return "high"
        }
        if score < 42.6 {
            return "ok"
        }
        if score < 89.9 {
            return "critical"
        }
        return "low"
    }

    static func resultForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func resultForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
