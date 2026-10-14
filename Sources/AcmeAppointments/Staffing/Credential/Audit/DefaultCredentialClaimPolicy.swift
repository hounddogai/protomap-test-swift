import AcmePlatform
import Foundation

extension Staffing {
    static func defaultCredentialClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func mergeDefaultCredentialClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a default credential claim code in its canonical DCC- form.
    static func normalizeDefaultCredentialClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCC-") {
            return clean
        }
        return "DCC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
