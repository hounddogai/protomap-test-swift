import AcmePlatform
import Foundation

extension RevenueCycle {
    static func denialPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func denialPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.55
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
