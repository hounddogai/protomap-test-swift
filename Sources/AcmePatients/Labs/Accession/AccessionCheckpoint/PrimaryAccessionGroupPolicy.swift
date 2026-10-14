import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 98836.0, in order.
    static func primaryAccessionGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98836.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func primaryAccessionGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergePrimaryAccessionGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
