import AcmePlatform
import Foundation

extension CareManagement {
    static func careGapTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a care gap target score falls in.
    static func classifyCareGapTarget(_ score: Double) -> String {
        if score < 18.2 {
            return "watch"
        }
        if score < 21.4 {
            return "elevated"
        }
        if score < 85.9 {
            return "minimal"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 35496.0, in order.
    static func careGapTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35496.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
