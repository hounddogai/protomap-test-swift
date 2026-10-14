import AcmePlatform
import Foundation

extension Consent {
    static func mergeWitnessBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a witness bundle code in its canonical WB- form.
    static func normalizeWitnessBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WB-") {
            return clean
        }
        return "WB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
