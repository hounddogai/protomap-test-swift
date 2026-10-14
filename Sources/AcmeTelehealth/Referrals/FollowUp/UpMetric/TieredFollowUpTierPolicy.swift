import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a tiered follow up tier code in its canonical TFUT- form.
    static func normalizeTieredFollowUpTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TFUT-") {
            return clean
        }
        return "TFUT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredFollowUpTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeTieredFollowUpTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
