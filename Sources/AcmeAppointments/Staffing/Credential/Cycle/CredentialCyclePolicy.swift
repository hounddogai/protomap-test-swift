import AcmePlatform
import Foundation

extension Staffing {
    static func credentialCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a credential cycle score falls in.
    static func classifyCredentialCycle(_ score: Double) -> String {
        if score < 12.1 {
            return "ok"
        }
        if score < 28.0 {
            return "elevated"
        }
        if score < 82.1 {
            return "watch"
        }
        if score < 84.5 {
            return "critical"
        }
        return "low"
    }
}
