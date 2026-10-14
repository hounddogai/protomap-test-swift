import AcmePlatform
import Foundation

extension Pharmacy {
    static func formularyPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 3816.0, in order.
    static func formularyPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3816.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a formulary plan score falls in.
    static func classifyFormularyPlan(_ score: Double) -> String {
        if score < 39.7 {
            return "ok"
        }
        if score < 43.3 {
            return "medium"
        }
        if score < 69.7 {
            return "high"
        }
        return "watch"
    }

    static func formularyPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
