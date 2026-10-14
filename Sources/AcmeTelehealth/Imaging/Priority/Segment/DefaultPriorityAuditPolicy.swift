import AcmePlatform
import Foundation

extension Imaging {
    static func defaultPriorityAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func defaultPriorityAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
