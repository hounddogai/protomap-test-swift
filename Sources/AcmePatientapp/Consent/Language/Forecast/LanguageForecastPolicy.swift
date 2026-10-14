import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 91928.0, in order.
    static func languageForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91928.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func languageForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a language forecast score falls in.
    static func classifyLanguageForecast(_ score: Double) -> String {
        if score < 1.0 {
            return "ok"
        }
        if score < 71.1 {
            return "medium"
        }
        return "minimal"
    }
}
