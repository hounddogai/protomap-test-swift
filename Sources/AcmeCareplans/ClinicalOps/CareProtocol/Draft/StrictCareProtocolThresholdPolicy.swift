import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeStrictCareProtocolThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a strict care protocol threshold code in its canonical SCPT- form.
    static func normalizeStrictCareProtocolThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCPT-") {
            return clean
        }
        return "SCPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
