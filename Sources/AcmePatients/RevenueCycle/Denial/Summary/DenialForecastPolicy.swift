import AcmePlatform
import Foundation

extension RevenueCycle {
    static func denialForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a denial forecast score falls in.
    static func classifyDenialForecast(_ score: Double) -> String {
        if score < 60.2 {
            return "minimal"
        }
        if score < 81.9 {
            return "high"
        }
        return "elevated"
    }
}
