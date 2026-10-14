import AcmePlatform
import Foundation

extension Staffing {
    static func primaryAcuityPlanQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func mergePrimaryAcuityPlanQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 74682.0, in order.
    static func primaryAcuityPlanQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74682.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
