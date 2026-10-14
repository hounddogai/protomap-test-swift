import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 39850.0, in order.
    static func pendingModalityPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39850.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a pending modality policy score falls in.
    static func classifyPendingModalityPolicy(_ score: Double) -> String {
        if score < 10.2 {
            return "ok"
        }
        if score < 67.1 {
            return "critical"
        }
        if score < 93.9 {
            return "medium"
        }
        return "watch"
    }

    static func pendingModalityPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
