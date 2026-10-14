import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 60458.0, in order.
    static func courierSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60458.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func courierSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func mergeCourierSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
