import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a weighted result rule score falls in.
    static func classifyWeightedResultRule(_ score: Double) -> String {
        if score < 5.1 {
            return "medium"
        }
        if score < 10.0 {
            return "minimal"
        }
        if score < 28.9 {
            return "low"
        }
        if score < 48.8 {
            return "elevated"
        }
        return "high"
    }

    static func weightedResultRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 11565.0, in order.
    static func weightedResultRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11565.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
