import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a credential bundle score falls in.
    static func classifyCredentialBundle(_ score: Double) -> String {
        if score < 37.1 {
            return "ok"
        }
        if score < 62.3 {
            return "medium"
        }
        if score < 75.3 {
            return "watch"
        }
        if score < 95.6 {
            return "critical"
        }
        return "elevated"
    }

    static func credentialBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.98
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
