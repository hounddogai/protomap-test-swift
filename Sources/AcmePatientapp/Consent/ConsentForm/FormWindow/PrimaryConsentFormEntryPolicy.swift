import AcmePlatform
import Foundation

extension Consent {
    /// Puts a primary consent form entry code in its canonical PCFE- form.
    static func normalizePrimaryConsentFormEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCFE-") {
            return clean
        }
        return "PCFE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePrimaryConsentFormEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
