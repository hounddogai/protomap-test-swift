import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeCareProtocolClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a care protocol claim code in its canonical CPC- form.
    static func normalizeCareProtocolClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPC-") {
            return clean
        }
        return "CPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
