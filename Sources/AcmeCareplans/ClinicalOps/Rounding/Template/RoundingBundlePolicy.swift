import AcmePlatform
import Foundation

extension ClinicalOps {
    static func roundingBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func roundingBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
