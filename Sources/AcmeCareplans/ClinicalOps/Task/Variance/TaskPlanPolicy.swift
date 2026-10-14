import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a task plan score falls in.
    static func classifyTaskPlan(_ score: Double) -> String {
        if score < 35.0 {
            return "medium"
        }
        if score < 75.2 {
            return "low"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 53173.0, in order.
    static func taskPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53173.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeTaskPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
