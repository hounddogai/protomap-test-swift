import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a global care protocol baseline score falls in.
    static func classifyGlobalCareProtocolBaseline(_ score: Double) -> String {
        if score < 8.8 {
            return "elevated"
        }
        if score < 46.7 {
            return "medium"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 43034.0, in order.
    static func globalCareProtocolBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43034.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
