import AcmePlatform
import Foundation

extension Consent {
    /// Puts a fallback disclosure adjustment code in its canonical FDA- form.
    static func normalizeFallbackDisclosureAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FDA-") {
            return clean
        }
        return "FDA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFallbackDisclosureAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
