import AcmePlatform
import Foundation

extension Labs {
    static func pendingResultForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a pending result forecast score falls in.
    static func classifyPendingResultForecast(_ score: Double) -> String {
        if score < 8.5 {
            return "minimal"
        }
        if score < 9.3 {
            return "medium"
        }
        if score < 17.2 {
            return "elevated"
        }
        if score < 37.5 {
            return "low"
        }
        return "ok"
    }
}
