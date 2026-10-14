import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeLenientInventoryPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 80928.0, in order.
    static func lenientInventoryPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80928.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
