import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveRevocationEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive revocation estimate score falls in.
    static func classifyAdaptiveRevocationEstimate(_ score: Double) -> String {
        if score < 19.9 {
            return "critical"
        }
        if score < 45.3 {
            return "medium"
        }
        return "elevated"
    }

    /// Puts a adaptive revocation estimate code in its canonical ARE- form.
    static func normalizeAdaptiveRevocationEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARE-") {
            return clean
        }
        return "ARE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveRevocationEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
