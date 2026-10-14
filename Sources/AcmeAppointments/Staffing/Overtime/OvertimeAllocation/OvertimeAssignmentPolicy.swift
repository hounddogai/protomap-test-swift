import AcmePlatform
import Foundation

extension Staffing {
    static func mergeOvertimeAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func overtimeAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 45321.0, in order.
    static func overtimeAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45321.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
