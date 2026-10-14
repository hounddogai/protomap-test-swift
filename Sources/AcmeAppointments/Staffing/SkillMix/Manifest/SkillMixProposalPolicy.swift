import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a skill mix proposal score falls in.
    static func classifySkillMixProposal(_ score: Double) -> String {
        if score < 35.8 {
            return "minimal"
        }
        if score < 41.8 {
            return "medium"
        }
        return "elevated"
    }

    static func skillMixProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
