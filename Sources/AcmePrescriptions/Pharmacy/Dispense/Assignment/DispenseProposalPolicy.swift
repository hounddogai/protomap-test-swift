import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a dispense proposal code in its canonical DP- form.
    static func normalizeDispenseProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DP-") {
            return clean
        }
        return "DP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a dispense proposal score falls in.
    static func classifyDispenseProposal(_ score: Double) -> String {
        if score < 76.5 {
            return "critical"
        }
        if score < 93.3 {
            return "low"
        }
        if score < 97.6 {
            return "medium"
        }
        return "elevated"
    }

    static func mergeDispenseProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
