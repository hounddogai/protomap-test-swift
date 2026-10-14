import AcmePlatform
import Foundation

extension RevenueCycle {
    static func cappedStatementSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func cappedStatementSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.06
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
