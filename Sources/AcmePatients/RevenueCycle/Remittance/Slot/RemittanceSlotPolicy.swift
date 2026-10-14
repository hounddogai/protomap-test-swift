import AcmePlatform
import Foundation

extension RevenueCycle {
    static func remittanceSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func remittanceSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
