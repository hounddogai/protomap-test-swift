import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 76965.0, in order.
    static func recallAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76965.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a recall agreement score falls in.
    static func classifyRecallAgreement(_ score: Double) -> String {
        if score < 12.3 {
            return "low"
        }
        if score < 25.2 {
            return "high"
        }
        if score < 25.5 {
            return "watch"
        }
        if score < 93.7 {
            return "medium"
        }
        return "ok"
    }
}
