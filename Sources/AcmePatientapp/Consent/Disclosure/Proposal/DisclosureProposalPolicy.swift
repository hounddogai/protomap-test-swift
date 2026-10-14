import AcmePlatform
import Foundation

extension Consent {
    static func disclosureProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a disclosure proposal score falls in.
    static func classifyDisclosureProposal(_ score: Double) -> String {
        if score < 9.4 {
            return "medium"
        }
        if score < 12.7 {
            return "ok"
        }
        if score < 33.3 {
            return "low"
        }
        return "critical"
    }
}
