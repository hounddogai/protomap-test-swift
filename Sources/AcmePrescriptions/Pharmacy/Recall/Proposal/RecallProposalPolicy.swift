import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a recall proposal code in its canonical RP- form.
    static func normalizeRecallProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RP-") {
            return clean
        }
        return "RP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func recallProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a recall proposal score falls in.
    static func classifyRecallProposal(_ score: Double) -> String {
        if score < 9.7 {
            return "critical"
        }
        if score < 64.2 {
            return "ok"
        }
        if score < 88.5 {
            return "medium"
        }
        return "watch"
    }

    static func mergeRecallProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
