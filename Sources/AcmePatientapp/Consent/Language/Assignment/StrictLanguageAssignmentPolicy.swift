import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a strict language assignment score falls in.
    static func classifyStrictLanguageAssignment(_ score: Double) -> String {
        if score < 24.1 {
            return "ok"
        }
        if score < 34.2 {
            return "watch"
        }
        if score < 42.1 {
            return "critical"
        }
        if score < 64.3 {
            return "minimal"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 26025.0, in order.
    static func strictLanguageAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26025.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictLanguageAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func strictLanguageAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
