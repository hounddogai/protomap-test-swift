import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 72555.0, in order.
    static func globalSpecimenLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72555.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeGlobalSpecimenLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func globalSpecimenLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
