import AcmePlatform
import Foundation

extension Labs {
    static func mergeReferenceRangeNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a reference range notice code in its canonical RRN- form.
    static func normalizeReferenceRangeNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRN-") {
            return clean
        }
        return "RRN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
