import AcmePlatform
import Foundation

extension Consent {
    static func proxyDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a proxy draft score falls in.
    static func classifyProxyDraft(_ score: Double) -> String {
        if score < 51.5 {
            return "low"
        }
        if score < 71.9 {
            return "elevated"
        }
        return "high"
    }
}
