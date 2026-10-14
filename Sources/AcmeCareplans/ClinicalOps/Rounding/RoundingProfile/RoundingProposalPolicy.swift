import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a rounding proposal score falls in.
    static func classifyRoundingProposal(_ score: Double) -> String {
        if score < 2.2 {
            return "minimal"
        }
        if score < 2.6 {
            return "watch"
        }
        if score < 20.1 {
            return "low"
        }
        if score < 45.4 {
            return "critical"
        }
        return "ok"
    }

    static func mergeRoundingProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
