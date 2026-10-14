import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeCareProtocolMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a care protocol metric code in its canonical CPM- form.
    static func normalizeCareProtocolMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPM-") {
            return clean
        }
        return "CPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
