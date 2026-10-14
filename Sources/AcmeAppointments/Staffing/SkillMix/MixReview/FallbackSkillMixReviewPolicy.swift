import AcmePlatform
import Foundation

extension Staffing {
    static func fallbackSkillMixReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func fallbackSkillMixReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a fallback skill mix review code in its canonical FSMR- form.
    static func normalizeFallbackSkillMixReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FSMR-") {
            return clean
        }
        return "FSMR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
