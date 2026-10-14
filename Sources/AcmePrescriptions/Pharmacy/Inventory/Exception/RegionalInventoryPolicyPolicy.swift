import AcmePlatform
import Foundation

extension Pharmacy {
    static func regionalInventoryPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func regionalInventoryPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a regional inventory policy score falls in.
    static func classifyRegionalInventoryPolicy(_ score: Double) -> String {
        if score < 1.0 {
            return "critical"
        }
        if score < 57.7 {
            return "elevated"
        }
        return "minimal"
    }
}
