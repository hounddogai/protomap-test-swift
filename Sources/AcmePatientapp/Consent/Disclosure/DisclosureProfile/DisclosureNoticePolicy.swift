import AcmePlatform
import Foundation

extension Consent {
    static func disclosureNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a disclosure notice code in its canonical DN- form.
    static func normalizeDisclosureNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DN-") {
            return clean
        }
        return "DN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDisclosureNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
