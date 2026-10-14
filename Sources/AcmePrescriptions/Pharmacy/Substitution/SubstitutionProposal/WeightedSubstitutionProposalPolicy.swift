import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a weighted substitution proposal score falls in.
    static func classifyWeightedSubstitutionProposal(_ score: Double) -> String {
        if score < 14.8 {
            return "critical"
        }
        if score < 30.4 {
            return "low"
        }
        return "minimal"
    }

    static func weightedSubstitutionProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
