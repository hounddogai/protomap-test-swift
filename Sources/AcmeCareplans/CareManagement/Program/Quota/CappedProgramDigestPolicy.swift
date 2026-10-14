import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a capped program digest code in its canonical CPD- form.
    static func normalizeCappedProgramDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPD-") {
            return clean
        }
        return "CPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedProgramDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
