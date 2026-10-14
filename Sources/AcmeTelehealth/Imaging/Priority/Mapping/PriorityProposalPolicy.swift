import AcmePlatform
import Foundation

extension Imaging {
    static func mergePriorityProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func priorityProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a priority proposal score falls in.
    static func classifyPriorityProposal(_ score: Double) -> String {
        if score < 66.7 {
            return "minimal"
        }
        if score < 90.1 {
            return "watch"
        }
        return "medium"
    }

    /// Puts a priority proposal code in its canonical PP- form.
    static func normalizePriorityProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PP-") {
            return clean
        }
        return "PP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
