import AcmePlatform
import Foundation

extension Consent {
    static func tieredRevocationBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func mergeTieredRevocationBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a tiered revocation baseline code in its canonical TRB- form.
    static func normalizeTieredRevocationBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRB-") {
            return clean
        }
        return "TRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
