import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a rolling alert proposal score falls in.
    static func classifyRollingAlertProposal(_ score: Double) -> String {
        if score < 18.1 {
            return "minimal"
        }
        if score < 25.7 {
            return "watch"
        }
        if score < 31.9 {
            return "ok"
        }
        if score < 57.4 {
            return "medium"
        }
        return "low"
    }

    static func mergeRollingAlertProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
