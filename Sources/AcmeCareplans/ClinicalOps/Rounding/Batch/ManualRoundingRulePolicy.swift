import AcmePlatform
import Foundation

extension ClinicalOps {
    static func manualRoundingRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 38860.0, in order.
    static func manualRoundingRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38860.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualRoundingRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
