import AcmePlatform
import Foundation

extension Staffing {
    static func defaultFloatPoolAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 52366.0, in order.
    static func defaultFloatPoolAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52366.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultFloatPoolAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a default float pool assignment score falls in.
    static func classifyDefaultFloatPoolAssignment(_ score: Double) -> String {
        if score < 1.0 {
            return "watch"
        }
        if score < 8.2 {
            return "ok"
        }
        if score < 10.2 {
            return "critical"
        }
        if score < 16.8 {
            return "elevated"
        }
        return "high"
    }
}
