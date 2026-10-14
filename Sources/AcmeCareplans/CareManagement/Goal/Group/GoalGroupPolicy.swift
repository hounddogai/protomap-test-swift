import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a goal group score falls in.
    static func classifyGoalGroup(_ score: Double) -> String {
        if score < 87.8 {
            return "minimal"
        }
        if score < 89.2 {
            return "watch"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 35062.0, in order.
    static func goalGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35062.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func goalGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
