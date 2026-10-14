import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality rule score falls in.
    static func classifyModalityRule(_ score: Double) -> String {
        if score < 19.1 {
            return "medium"
        }
        if score < 37.8 {
            return "ok"
        }
        if score < 73.3 {
            return "critical"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 63754.0, in order.
    static func modalityRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63754.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
