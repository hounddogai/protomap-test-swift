import AcmePlatform
import Foundation

extension CareManagement {
    static func legacyRiskScoreOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeLegacyRiskScoreOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy risk score override code in its canonical LRSO- form.
    static func normalizeLegacyRiskScoreOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRSO-") {
            return clean
        }
        return "LRSO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
