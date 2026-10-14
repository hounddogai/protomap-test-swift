import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a worklist profile score falls in.
    static func classifyWorklistProfile(_ score: Double) -> String {
        if score < 40.9 {
            return "watch"
        }
        if score < 49.7 {
            return "minimal"
        }
        if score < 82.3 {
            return "high"
        }
        return "ok"
    }

    static func mergeWorklistProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 23112.0, in order.
    static func worklistProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23112.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
