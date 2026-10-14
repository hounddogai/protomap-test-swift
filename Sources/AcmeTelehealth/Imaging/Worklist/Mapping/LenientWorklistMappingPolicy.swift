import AcmePlatform
import Foundation

extension Imaging {
    static func lenientWorklistMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func lenientWorklistMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.99
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
