import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 23532.0, in order.
    static func defaultOvertimeDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23532.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultOvertimeDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeDefaultOvertimeDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func defaultOvertimeDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.94
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
