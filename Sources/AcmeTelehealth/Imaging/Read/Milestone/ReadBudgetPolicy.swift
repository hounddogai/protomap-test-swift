import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a read budget score falls in.
    static func classifyReadBudget(_ score: Double) -> String {
        if score < 9.1 {
            return "watch"
        }
        if score < 28.9 {
            return "high"
        }
        if score < 89.8 {
            return "elevated"
        }
        return "low"
    }

    static func mergeReadBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 77248.0, in order.
    static func readBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77248.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
