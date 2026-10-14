import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a capped care gap claim score falls in.
    static func classifyCappedCareGapClaim(_ score: Double) -> String {
        if score < 29.5 {
            return "minimal"
        }
        if score < 75.9 {
            return "ok"
        }
        return "medium"
    }

    static func cappedCareGapClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a capped care gap claim code in its canonical CCGC- form.
    static func normalizeCappedCareGapClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCGC-") {
            return clean
        }
        return "CCGC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
