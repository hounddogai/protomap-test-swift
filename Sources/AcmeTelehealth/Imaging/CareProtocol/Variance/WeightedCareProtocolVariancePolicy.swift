import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a weighted care protocol variance score falls in.
    static func classifyWeightedCareProtocolVariance(_ score: Double) -> String {
        if score < 61.6 {
            return "critical"
        }
        if score < 70.1 {
            return "elevated"
        }
        if score < 77.2 {
            return "watch"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 29392.0, in order.
    static func weightedCareProtocolVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29392.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
