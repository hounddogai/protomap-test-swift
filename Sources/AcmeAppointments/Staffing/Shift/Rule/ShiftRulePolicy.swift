import AcmePlatform
import Foundation

extension Staffing {
    static func shiftRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 52052.0, in order.
    static func shiftRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52052.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a shift rule score falls in.
    static func classifyShiftRule(_ score: Double) -> String {
        if score < 8.2 {
            return "elevated"
        }
        if score < 30.7 {
            return "medium"
        }
        if score < 70.1 {
            return "ok"
        }
        return "low"
    }

    static func shiftRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
