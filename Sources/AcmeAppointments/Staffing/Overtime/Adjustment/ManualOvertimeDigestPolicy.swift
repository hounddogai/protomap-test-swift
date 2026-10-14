import AcmePlatform
import Foundation

extension Staffing {
    static func manualOvertimeDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func manualOvertimeDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
