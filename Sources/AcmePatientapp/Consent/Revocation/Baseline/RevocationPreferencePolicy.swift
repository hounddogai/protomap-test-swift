import AcmePlatform
import Foundation

extension Consent {
    static func mergeRevocationPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a revocation preference code in its canonical RP- form.
    static func normalizeRevocationPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RP-") {
            return clean
        }
        return "RP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
