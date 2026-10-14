import AcmePlatform
import Foundation

extension Staffing {
    static func seasonalSkillMixProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.4
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a seasonal skill mix proposal score falls in.
    static func classifySeasonalSkillMixProposal(_ score: Double) -> String {
        if score < 14.9 {
            return "watch"
        }
        if score < 15.2 {
            return "ok"
        }
        if score < 18.1 {
            return "elevated"
        }
        if score < 30.6 {
            return "minimal"
        }
        return "medium"
    }
}
