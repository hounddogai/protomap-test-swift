import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 2466.0, in order.
    static func defaultRecallGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2466.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeDefaultRecallGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default recall group score falls in.
    static func classifyDefaultRecallGroup(_ score: Double) -> String {
        if score < 24.2 {
            return "minimal"
        }
        if score < 61.1 {
            return "medium"
        }
        if score < 61.7 {
            return "critical"
        }
        return "high"
    }

    static func defaultRecallGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
