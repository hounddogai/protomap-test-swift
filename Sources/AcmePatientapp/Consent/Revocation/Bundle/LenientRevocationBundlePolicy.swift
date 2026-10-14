import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a lenient revocation bundle score falls in.
    static func classifyLenientRevocationBundle(_ score: Double) -> String {
        if score < 17.4 {
            return "high"
        }
        if score < 62.3 {
            return "medium"
        }
        return "low"
    }

    static func lenientRevocationBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
