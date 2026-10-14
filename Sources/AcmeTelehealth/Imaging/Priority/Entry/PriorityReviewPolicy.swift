import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 73237.0, in order.
    static func priorityReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73237.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func priorityReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergePriorityReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func priorityReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.26
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
