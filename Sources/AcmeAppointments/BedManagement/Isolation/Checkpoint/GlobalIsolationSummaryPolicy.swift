import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 69890.0, in order.
    static func globalIsolationSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69890.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a global isolation summary score falls in.
    static func classifyGlobalIsolationSummary(_ score: Double) -> String {
        if score < 3.7 {
            return "minimal"
        }
        if score < 56.9 {
            return "high"
        }
        return "ok"
    }

    static func globalIsolationSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func globalIsolationSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
