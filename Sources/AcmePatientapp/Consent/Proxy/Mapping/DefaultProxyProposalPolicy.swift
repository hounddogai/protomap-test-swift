import AcmePlatform
import Foundation

extension Consent {
    static func mergeDefaultProxyProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func defaultProxyProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a default proxy proposal code in its canonical DPP- form.
    static func normalizeDefaultProxyProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPP-") {
            return clean
        }
        return "DPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
