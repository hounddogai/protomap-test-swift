import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a capped isolation review code in its canonical CIR- form.
    static func normalizeCappedIsolationReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CIR-") {
            return clean
        }
        return "CIR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedIsolationReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
