import AcmePlatform
import Foundation

extension Labs {
    static func pendingReferenceRangeSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func pendingReferenceRangeSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func pendingReferenceRangeSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
