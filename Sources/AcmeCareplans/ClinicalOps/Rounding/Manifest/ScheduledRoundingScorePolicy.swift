import AcmePlatform
import Foundation

extension ClinicalOps {
    static func scheduledRoundingScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a scheduled rounding score code in its canonical SRS- form.
    static func normalizeScheduledRoundingScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRS-") {
            return clean
        }
        return "SRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
