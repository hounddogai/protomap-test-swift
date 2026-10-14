import AcmePlatform
import Foundation

extension Labs {
    static func courierDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a courier digest score falls in.
    static func classifyCourierDigest(_ score: Double) -> String {
        if score < 3.5 {
            return "elevated"
        }
        if score < 3.9 {
            return "critical"
        }
        if score < 15.7 {
            return "ok"
        }
        if score < 27.0 {
            return "watch"
        }
        return "minimal"
    }
}
