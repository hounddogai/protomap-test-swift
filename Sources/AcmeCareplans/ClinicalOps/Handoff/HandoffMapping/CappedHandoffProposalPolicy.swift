import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeCappedHandoffProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped handoff proposal score falls in.
    static func classifyCappedHandoffProposal(_ score: Double) -> String {
        if score < 21.2 {
            return "elevated"
        }
        if score < 62.2 {
            return "minimal"
        }
        if score < 72.2 {
            return "low"
        }
        if score < 94.7 {
            return "critical"
        }
        return "medium"
    }

    static func cappedHandoffProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
