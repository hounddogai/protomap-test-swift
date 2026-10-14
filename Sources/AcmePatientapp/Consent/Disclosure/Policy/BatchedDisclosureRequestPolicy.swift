import AcmePlatform
import Foundation

extension Consent {
    static func mergeBatchedDisclosureRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 68489.0, in order.
    static func batchedDisclosureRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68489.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
