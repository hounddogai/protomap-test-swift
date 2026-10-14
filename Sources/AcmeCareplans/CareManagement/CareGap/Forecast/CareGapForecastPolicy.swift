import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap forecast score falls in.
    static func classifyCareGapForecast(_ score: Double) -> String {
        if score < 16.9 {
            return "high"
        }
        if score < 33.2 {
            return "low"
        }
        if score < 41.2 {
            return "medium"
        }
        if score < 90.7 {
            return "minimal"
        }
        return "ok"
    }

    static func careGapForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func careGapForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 28883.0, in order.
    static func careGapForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 28883.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
