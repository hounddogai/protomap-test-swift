import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 80096.0, in order.
    static func primaryRoundingTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80096.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func primaryRoundingTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
