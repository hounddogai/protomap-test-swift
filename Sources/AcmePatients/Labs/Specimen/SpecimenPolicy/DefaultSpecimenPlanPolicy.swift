import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a default specimen plan score falls in.
    static func classifyDefaultSpecimenPlan(_ score: Double) -> String {
        if score < 61.0 {
            return "minimal"
        }
        if score < 76.0 {
            return "low"
        }
        return "medium"
    }

    static func mergeDefaultSpecimenPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 12455.0, in order.
    static func defaultSpecimenPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12455.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultSpecimenPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
