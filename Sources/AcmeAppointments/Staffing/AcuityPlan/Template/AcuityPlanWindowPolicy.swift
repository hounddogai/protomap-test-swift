import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 17010.0, in order.
    static func acuityPlanWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17010.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a acuity plan window score falls in.
    static func classifyAcuityPlanWindow(_ score: Double) -> String {
        if score < 8.8 {
            return "medium"
        }
        if score < 54.9 {
            return "minimal"
        }
        if score < 74.7 {
            return "high"
        }
        return "watch"
    }

    static func mergeAcuityPlanWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func acuityPlanWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
