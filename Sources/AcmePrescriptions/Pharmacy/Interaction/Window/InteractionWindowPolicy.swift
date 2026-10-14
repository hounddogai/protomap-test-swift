import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a interaction window score falls in.
    static func classifyInteractionWindow(_ score: Double) -> String {
        if score < 5.7 {
            return "minimal"
        }
        if score < 21.5 {
            return "critical"
        }
        if score < 29.1 {
            return "ok"
        }
        if score < 64.0 {
            return "watch"
        }
        return "medium"
    }

    static func interactionWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
