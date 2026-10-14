import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 29750.0, in order.
    static func recallEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29750.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func recallEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func recallEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Names the band a recall entry score falls in.
    static func classifyRecallEntry(_ score: Double) -> String {
        if score < 9.3 {
            return "ok"
        }
        if score < 48.2 {
            return "minimal"
        }
        if score < 51.9 {
            return "low"
        }
        if score < 91.6 {
            return "elevated"
        }
        return "high"
    }
}
