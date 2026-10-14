import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a task budget score falls in.
    static func classifyTaskBudget(_ score: Double) -> String {
        if score < 51.3 {
            return "high"
        }
        if score < 77.5 {
            return "minimal"
        }
        if score < 91.4 {
            return "medium"
        }
        return "watch"
    }

    static func mergeTaskBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 13285.0, in order.
    static func taskBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13285.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func taskBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
