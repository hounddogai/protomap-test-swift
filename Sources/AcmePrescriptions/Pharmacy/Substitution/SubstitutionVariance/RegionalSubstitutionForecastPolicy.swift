import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a regional substitution forecast score falls in.
    static func classifyRegionalSubstitutionForecast(_ score: Double) -> String {
        if score < 16.7 {
            return "critical"
        }
        if score < 22.7 {
            return "medium"
        }
        if score < 28.0 {
            return "watch"
        }
        if score < 54.4 {
            return "minimal"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 69050.0, in order.
    static func regionalSubstitutionForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69050.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func regionalSubstitutionForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func regionalSubstitutionForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
