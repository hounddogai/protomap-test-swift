import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 97190.0, in order.
    static func prioritySegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97190.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a priority segment score falls in.
    static func classifyPrioritySegment(_ score: Double) -> String {
        if score < 11.7 {
            return "watch"
        }
        if score < 13.1 {
            return "medium"
        }
        if score < 14.2 {
            return "ok"
        }
        if score < 38.0 {
            return "elevated"
        }
        return "critical"
    }

    static func prioritySegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
