import AcmePlatform
import Foundation

extension ClinicalOps {
    static func regionalAlertTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func regionalAlertTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a regional alert tier score falls in.
    static func classifyRegionalAlertTier(_ score: Double) -> String {
        if score < 33.8 {
            return "low"
        }
        if score < 78.9 {
            return "elevated"
        }
        return "watch"
    }

    /// Puts a regional alert tier code in its canonical RAT- form.
    static func normalizeRegionalAlertTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAT-") {
            return clean
        }
        return "RAT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
