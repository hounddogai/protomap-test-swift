import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a formulary entry code in its canonical FE- form.
    static func normalizeFormularyEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FE-") {
            return clean
        }
        return "FE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFormularyEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
