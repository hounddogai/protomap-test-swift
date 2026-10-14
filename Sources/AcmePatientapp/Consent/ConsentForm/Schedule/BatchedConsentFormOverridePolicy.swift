import AcmePlatform
import Foundation

extension Consent {
    /// Puts a batched consent form override code in its canonical BCFO- form.
    static func normalizeBatchedConsentFormOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCFO-") {
            return clean
        }
        return "BCFO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeBatchedConsentFormOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
