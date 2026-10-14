import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a capped result override score falls in.
    static func classifyCappedResultOverride(_ score: Double) -> String {
        if score < 6.2 {
            return "critical"
        }
        if score < 39.5 {
            return "high"
        }
        if score < 78.9 {
            return "medium"
        }
        return "minimal"
    }

    static func cappedResultOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func cappedResultOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 15855.0, in order.
    static func cappedResultOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15855.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
