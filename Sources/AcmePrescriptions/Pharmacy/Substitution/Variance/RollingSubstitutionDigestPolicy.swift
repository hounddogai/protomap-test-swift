import AcmePlatform
import Foundation

extension Pharmacy {
    static func rollingSubstitutionDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a rolling substitution digest code in its canonical RSD- form.
    static func normalizeRollingSubstitutionDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSD-") {
            return clean
        }
        return "RSD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling substitution digest score falls in.
    static func classifyRollingSubstitutionDigest(_ score: Double) -> String {
        if score < 36.3 {
            return "medium"
        }
        if score < 56.6 {
            return "minimal"
        }
        if score < 80.6 {
            return "low"
        }
        return "critical"
    }
}
