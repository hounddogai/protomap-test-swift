import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 76185.0, in order.
    static func overtimeOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76185.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a overtime override score falls in.
    static func classifyOvertimeOverride(_ score: Double) -> String {
        if score < 26.2 {
            return "high"
        }
        if score < 62.8 {
            return "elevated"
        }
        if score < 83.8 {
            return "ok"
        }
        return "minimal"
    }

    static func mergeOvertimeOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func overtimeOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
