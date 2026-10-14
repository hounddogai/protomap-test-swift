import AcmePlatform
import Foundation

extension ClinicalOps {
    static func pendingHandoffBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func pendingHandoffBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
