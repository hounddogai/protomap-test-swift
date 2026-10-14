import AcmePlatform
import Foundation

extension ClinicalOps {
    static func taskProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a task proposal score falls in.
    static func classifyTaskProposal(_ score: Double) -> String {
        if score < 46.3 {
            return "elevated"
        }
        if score < 54.8 {
            return "minimal"
        }
        if score < 81.0 {
            return "high"
        }
        return "medium"
    }
}
