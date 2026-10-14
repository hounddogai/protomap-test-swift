import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a weighted read preference score falls in.
    static func classifyWeightedReadPreference(_ score: Double) -> String {
        if score < 81.9 {
            return "watch"
        }
        if score < 82.7 {
            return "critical"
        }
        if score < 86.0 {
            return "high"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 54997.0, in order.
    static func weightedReadPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54997.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedReadPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
