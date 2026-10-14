import AcmePlatform
import Foundation

extension Imaging {
    static func adaptivePriorityOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func adaptivePriorityOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
