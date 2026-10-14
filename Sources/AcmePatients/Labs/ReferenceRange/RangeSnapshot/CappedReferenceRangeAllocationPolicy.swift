import AcmePlatform
import Foundation

extension Labs {
    static func cappedReferenceRangeAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    static func cappedReferenceRangeAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
