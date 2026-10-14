import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a pending formulary proposal score falls in.
    static func classifyPendingFormularyProposal(_ score: Double) -> String {
        if score < 3.0 {
            return "elevated"
        }
        if score < 53.2 {
            return "minimal"
        }
        return "critical"
    }

    static func pendingFormularyProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
