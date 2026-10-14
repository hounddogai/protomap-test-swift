import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a default rounding draft code in its canonical DRD- form.
    static func normalizeDefaultRoundingDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRD-") {
            return clean
        }
        return "DRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a default rounding draft score falls in.
    static func classifyDefaultRoundingDraft(_ score: Double) -> String {
        if score < 52.3 {
            return "critical"
        }
        if score < 75.2 {
            return "medium"
        }
        return "elevated"
    }

    static func defaultRoundingDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
