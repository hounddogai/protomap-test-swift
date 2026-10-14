import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a seasonal skill mix audit code in its canonical SSMA- form.
    static func normalizeSeasonalSkillMixAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSMA-") {
            return clean
        }
        return "SSMA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalSkillMixAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
