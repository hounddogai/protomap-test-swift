import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a primary interaction baseline code in its canonical PIB- form.
    static func normalizePrimaryInteractionBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIB-") {
            return clean
        }
        return "PIB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePrimaryInteractionBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
