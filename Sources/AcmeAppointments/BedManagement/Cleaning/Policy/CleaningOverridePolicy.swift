import AcmePlatform
import Foundation

extension BedManagement {
    static func cleaningOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func cleaningOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a cleaning override score falls in.
    static func classifyCleaningOverride(_ score: Double) -> String {
        if score < 24.5 {
            return "elevated"
        }
        if score < 84.9 {
            return "watch"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 1300.0, in order.
    static func cleaningOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1300.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
