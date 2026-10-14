import AcmePlatform
import Foundation

extension Consent {
    /// Puts a regional proxy baseline code in its canonical RPB- form.
    static func normalizeRegionalProxyBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPB-") {
            return clean
        }
        return "RPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalProxyBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a regional proxy baseline score falls in.
    static func classifyRegionalProxyBaseline(_ score: Double) -> String {
        if score < 9.1 {
            return "high"
        }
        if score < 97.0 {
            return "low"
        }
        return "minimal"
    }
}
