import AcmePlatform
import Foundation

extension ClinicalOps {
    static func globalRoundingClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func globalRoundingClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a global rounding claim code in its canonical GRC- form.
    static func normalizeGlobalRoundingClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GRC-") {
            return clean
        }
        return "GRC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a global rounding claim score falls in.
    static func classifyGlobalRoundingClaim(_ score: Double) -> String {
        if score < 41.8 {
            return "medium"
        }
        if score < 53.0 {
            return "low"
        }
        if score < 99.8 {
            return "critical"
        }
        return "elevated"
    }
}
