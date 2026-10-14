import AcmePlatform
import Foundation

extension BedManagement {
    static func transferMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func transferMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
