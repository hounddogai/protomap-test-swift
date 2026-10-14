import AcmePlatform
import Foundation

extension Imaging {
    static func readAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a read assignment score falls in.
    static func classifyReadAssignment(_ score: Double) -> String {
        if score < 41.2 {
            return "low"
        }
        if score < 48.8 {
            return "watch"
        }
        if score < 80.3 {
            return "critical"
        }
        if score < 84.2 {
            return "ok"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 83791.0, in order.
    static func readAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83791.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func readAssignmentSpan(_ start: Int, end: Int) -> Int {
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
