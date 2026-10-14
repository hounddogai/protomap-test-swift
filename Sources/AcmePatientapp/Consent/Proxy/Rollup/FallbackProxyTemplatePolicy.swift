import AcmePlatform
import Foundation

extension Consent {
    static func mergeFallbackProxyTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a fallback proxy template code in its canonical FPT- form.
    static func normalizeFallbackProxyTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPT-") {
            return clean
        }
        return "FPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
