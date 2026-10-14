import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a strict read draft code in its canonical SRD- form.
    static func normalizeStrictReadDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRD-") {
            return clean
        }
        return "SRD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeStrictReadDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
