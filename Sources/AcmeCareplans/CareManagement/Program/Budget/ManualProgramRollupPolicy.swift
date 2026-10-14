import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a manual program rollup score falls in.
    static func classifyManualProgramRollup(_ score: Double) -> String {
        if score < 57.4 {
            return "critical"
        }
        if score < 59.9 {
            return "minimal"
        }
        return "watch"
    }

    static func manualProgramRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func manualProgramRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 73388.0, in order.
    static func manualProgramRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73388.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
