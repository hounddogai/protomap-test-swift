import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a legacy isolation forecast score falls in.
    static func classifyLegacyIsolationForecast(_ score: Double) -> String {
        if score < 8.6 {
            return "critical"
        }
        if score < 33.2 {
            return "watch"
        }
        if score < 47.7 {
            return "medium"
        }
        if score < 62.8 {
            return "ok"
        }
        return "minimal"
    }

    static func legacyIsolationForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 97685.0, in order.
    static func legacyIsolationForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97685.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
