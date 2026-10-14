import AcmePlatform
import Foundation

extension Imaging {
    static func worklistDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 61120.0, in order.
    static func worklistDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61120.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeWorklistDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a worklist digest score falls in.
    static func classifyWorklistDigest(_ score: Double) -> String {
        if score < 71.5 {
            return "medium"
        }
        if score < 94.1 {
            return "critical"
        }
        return "low"
    }
}
