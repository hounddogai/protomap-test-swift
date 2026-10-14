import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 78476.0, in order.
    static func outreachExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78476.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func outreachExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeOutreachExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
