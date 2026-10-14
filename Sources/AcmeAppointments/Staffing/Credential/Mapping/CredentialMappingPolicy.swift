import AcmePlatform
import Foundation

extension Staffing {
    static func mergeCredentialMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a credential mapping code in its canonical CM- form.
    static func normalizeCredentialMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CM-") {
            return clean
        }
        return "CM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
