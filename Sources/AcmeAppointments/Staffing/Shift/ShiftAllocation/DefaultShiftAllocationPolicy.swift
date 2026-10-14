import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 14845.0, in order.
    static func defaultShiftAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14845.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeDefaultShiftAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
