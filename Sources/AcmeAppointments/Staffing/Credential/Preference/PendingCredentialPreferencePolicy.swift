import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a pending credential preference code in its canonical PCP- form.
    static func normalizePendingCredentialPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCP-") {
            return clean
        }
        return "PCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePendingCredentialPreferenceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
