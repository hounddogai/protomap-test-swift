import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a regional interaction window score falls in.
    static func classifyRegionalInteractionWindow(_ score: Double) -> String {
        if score < 1.9 {
            return "minimal"
        }
        if score < 26.1 {
            return "medium"
        }
        if score < 85.4 {
            return "high"
        }
        return "low"
    }

    static func regionalInteractionWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func regionalInteractionWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
