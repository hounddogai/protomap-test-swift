import AcmePlatform
import Foundation

extension Labs {
    static func manualResultDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func manualResultDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
