import AcmePlatform
import Foundation

extension Imaging {
    static func mergeReadBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 85528.0, in order.
    static func readBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85528.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a read baseline score falls in.
    static func classifyReadBaseline(_ score: Double) -> String {
        if score < 1.2 {
            return "ok"
        }
        if score < 17.2 {
            return "critical"
        }
        if score < 46.9 {
            return "low"
        }
        if score < 58.5 {
            return "watch"
        }
        return "elevated"
    }

    static func readBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
