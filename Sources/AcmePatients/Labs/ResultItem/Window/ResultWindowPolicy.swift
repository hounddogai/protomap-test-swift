import AcmePlatform
import Foundation

extension Labs {
    static func resultWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a result window score falls in.
    static func classifyResultWindow(_ score: Double) -> String {
        if score < 28.1 {
            return "ok"
        }
        if score < 53.2 {
            return "medium"
        }
        return "elevated"
    }
}
