import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 72058.0, in order.
    static func closureDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72058.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a closure digest score falls in.
    static func classifyClosureDigest(_ score: Double) -> String {
        if score < 19.8 {
            return "high"
        }
        if score < 28.8 {
            return "medium"
        }
        if score < 29.3 {
            return "elevated"
        }
        if score < 49.5 {
            return "ok"
        }
        return "critical"
    }

    static func closureDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
