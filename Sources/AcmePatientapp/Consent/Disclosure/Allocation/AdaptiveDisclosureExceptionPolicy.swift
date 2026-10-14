import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveDisclosureExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func adaptiveDisclosureExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive disclosure exception score falls in.
    static func classifyAdaptiveDisclosureException(_ score: Double) -> String {
        if score < 34.7 {
            return "critical"
        }
        if score < 59.1 {
            return "medium"
        }
        if score < 70.2 {
            return "elevated"
        }
        if score < 88.3 {
            return "ok"
        }
        return "watch"
    }
}
