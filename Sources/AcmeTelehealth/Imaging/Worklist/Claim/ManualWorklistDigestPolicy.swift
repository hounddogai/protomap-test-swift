import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 75723.0, in order.
    static func manualWorklistDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75723.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual worklist digest score falls in.
    static func classifyManualWorklistDigest(_ score: Double) -> String {
        if score < 30.7 {
            return "minimal"
        }
        if score < 40.4 {
            return "medium"
        }
        return "watch"
    }
}
