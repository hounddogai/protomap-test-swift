import AcmePlatform
import Foundation

extension Labs {
    static func referenceRangeCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Names the band a reference range cycle score falls in.
    static func classifyReferenceRangeCycle(_ score: Double) -> String {
        if score < 15.8 {
            return "elevated"
        }
        if score < 86.5 {
            return "high"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 23784.0, in order.
    static func referenceRangeCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23784.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
