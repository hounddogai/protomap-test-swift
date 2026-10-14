import AcmePlatform
import Foundation

extension Labs {
    /// Puts a accession variance code in its canonical AV- form.
    static func normalizeAccessionVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AV-") {
            return clean
        }
        return "AV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAccessionVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
