import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a weighted proxy group score falls in.
    static func classifyWeightedProxyGroup(_ score: Double) -> String {
        if score < 66.4 {
            return "watch"
        }
        if score < 99.6 {
            return "ok"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 53651.0, in order.
    static func weightedProxyGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53651.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedProxyGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func weightedProxyGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
