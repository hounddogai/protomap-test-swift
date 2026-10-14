import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol forecast score falls in.
    static func classifyCareProtocolForecast(_ score: Double) -> String {
        if score < 57.2 {
            return "high"
        }
        if score < 59.9 {
            return "elevated"
        }
        if score < 66.7 {
            return "minimal"
        }
        if score < 88.6 {
            return "critical"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 88982.0, in order.
    static func careProtocolForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 88982.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
