import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 44242.0, in order.
    static func priorityRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44242.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func priorityRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a priority rollup score falls in.
    static func classifyPriorityRollup(_ score: Double) -> String {
        if score < 5.6 {
            return "high"
        }
        if score < 96.4 {
            return "minimal"
        }
        return "watch"
    }

    static func priorityRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
