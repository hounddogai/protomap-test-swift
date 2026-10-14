import AcmePlatform
import Foundation

extension Labs {
    /// Puts a scheduled accession digest code in its canonical SAD- form.
    static func normalizeScheduledAccessionDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAD-") {
            return clean
        }
        return "SAD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeScheduledAccessionDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
