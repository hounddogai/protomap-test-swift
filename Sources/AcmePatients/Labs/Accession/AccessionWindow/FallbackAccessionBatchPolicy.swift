import AcmePlatform
import Foundation

extension Labs {
    /// Puts a fallback accession batch code in its canonical FAB- form.
    static func normalizeFallbackAccessionBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FAB-") {
            return clean
        }
        return "FAB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFallbackAccessionBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
