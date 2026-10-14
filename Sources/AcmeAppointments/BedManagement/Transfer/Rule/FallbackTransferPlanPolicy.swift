import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a fallback transfer plan score falls in.
    static func classifyFallbackTransferPlan(_ score: Double) -> String {
        if score < 35.9 {
            return "medium"
        }
        if score < 72.9 {
            return "elevated"
        }
        return "high"
    }

    static func fallbackTransferPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 98466.0, in order.
    static func fallbackTransferPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98466.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeFallbackTransferPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
