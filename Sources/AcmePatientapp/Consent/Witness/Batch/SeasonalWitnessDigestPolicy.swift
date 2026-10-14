import AcmePlatform
import Foundation

extension Consent {
    /// Puts a seasonal witness digest code in its canonical SWD- form.
    static func normalizeSeasonalWitnessDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SWD-") {
            return clean
        }
        return "SWD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeSeasonalWitnessDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
