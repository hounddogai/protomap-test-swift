import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a study forecast score falls in.
    static func classifyStudyForecast(_ score: Double) -> String {
        if score < 5.3 {
            return "elevated"
        }
        if score < 8.4 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 9687.0, in order.
    static func studyForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9687.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func studyForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
