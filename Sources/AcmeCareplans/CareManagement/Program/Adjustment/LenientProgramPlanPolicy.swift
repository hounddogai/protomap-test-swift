import AcmePlatform
import Foundation

extension CareManagement {
    static func lenientProgramPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.99
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 27249.0, in order.
    static func lenientProgramPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27249.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a lenient program plan score falls in.
    static func classifyLenientProgramPlan(_ score: Double) -> String {
        if score < 5.7 {
            return "low"
        }
        if score < 50.5 {
            return "watch"
        }
        if score < 74.8 {
            return "high"
        }
        return "medium"
    }
}
