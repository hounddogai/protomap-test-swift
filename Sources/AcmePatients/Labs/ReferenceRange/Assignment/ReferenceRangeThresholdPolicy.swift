import AcmePlatform
import Foundation

extension Labs {
    /// Puts a reference range threshold code in its canonical RRT- form.
    static func normalizeReferenceRangeThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRT-") {
            return clean
        }
        return "RRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeReferenceRangeThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
