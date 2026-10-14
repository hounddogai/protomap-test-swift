import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a primary discharge plan proposal score falls in.
    static func classifyPrimaryDischargePlanProposal(_ score: Double) -> String {
        if score < 31.9 {
            return "watch"
        }
        if score < 86.5 {
            return "critical"
        }
        return "elevated"
    }

    static func mergePrimaryDischargePlanProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func primaryDischargePlanProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a primary discharge plan proposal code in its canonical PDPP- form.
    static func normalizePrimaryDischargePlanProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PDPP-") {
            return clean
        }
        return "PDPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
