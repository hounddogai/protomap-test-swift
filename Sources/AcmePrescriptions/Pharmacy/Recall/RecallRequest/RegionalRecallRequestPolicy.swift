import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 84354.0, in order.
    static func regionalRecallRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84354.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a regional recall request score falls in.
    static func classifyRegionalRecallRequest(_ score: Double) -> String {
        if score < 1.6 {
            return "minimal"
        }
        if score < 64.1 {
            return "elevated"
        }
        if score < 90.1 {
            return "watch"
        }
        return "ok"
    }
}
