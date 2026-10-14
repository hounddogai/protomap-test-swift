import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 86130.0, in order.
    static func statementAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 86130.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a statement allocation score falls in.
    static func classifyStatementAllocation(_ score: Double) -> String {
        if score < 6.7 {
            return "minimal"
        }
        if score < 79.2 {
            return "low"
        }
        if score < 89.6 {
            return "medium"
        }
        return "critical"
    }

    static func statementAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
