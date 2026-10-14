import AcmePlatform
import Foundation

extension Consent {
    static func witnessProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a witness proposal score falls in.
    static func classifyWitnessProposal(_ score: Double) -> String {
        if score < 79.5 {
            return "ok"
        }
        if score < 99.5 {
            return "medium"
        }
        return "elevated"
    }
}
