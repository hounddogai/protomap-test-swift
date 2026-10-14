import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a legacy skill mix bundle code in its canonical LSMB- form.
    static func normalizeLegacySkillMixBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LSMB-") {
            return clean
        }
        return "LSMB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy skill mix bundle score falls in.
    static func classifyLegacySkillMixBundle(_ score: Double) -> String {
        if score < 3.8 {
            return "ok"
        }
        if score < 48.3 {
            return "elevated"
        }
        return "medium"
    }

    static func legacySkillMixBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
