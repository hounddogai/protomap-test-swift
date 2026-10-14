import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 85641.0, in order.
    static func pendingReferenceRangeScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85641.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a pending reference range score score falls in.
    static func classifyPendingReferenceRangeScore(_ score: Double) -> String {
        if score < 54.4 {
            return "ok"
        }
        if score < 76.8 {
            return "critical"
        }
        if score < 92.3 {
            return "minimal"
        }
        return "watch"
    }

    static func pendingReferenceRangeScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
