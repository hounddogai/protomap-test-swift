import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a tiered recall record code in its canonical TRR- form.
    static func normalizeTieredRecallRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRR-") {
            return clean
        }
        return "TRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeTieredRecallRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
