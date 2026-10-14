import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyReferenceRangeForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-reference-range-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a legacy reference range forecast score falls in.
    static func classifyLegacyReferenceRangeForecast(_ score: Double) -> String {
        if score < 26.2 {
            return "critical"
        }
        if score < 84.5 {
            return "watch"
        }
        return "medium"
    }

    static func legacyReferenceRangeForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func legacyReferenceRangeForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
