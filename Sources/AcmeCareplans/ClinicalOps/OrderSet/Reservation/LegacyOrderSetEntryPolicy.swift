import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeLegacyOrderSetEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy order set entry code in its canonical LOSE- form.
    static func normalizeLegacyOrderSetEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LOSE-") {
            return clean
        }
        return "LOSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyOrderSetEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
