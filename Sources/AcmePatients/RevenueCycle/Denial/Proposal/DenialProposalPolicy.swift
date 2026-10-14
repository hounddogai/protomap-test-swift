import AcmePlatform
import Foundation

extension RevenueCycle {
    static func denialProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a denial proposal score falls in.
    static func classifyDenialProposal(_ score: Double) -> String {
        if score < 29.0 {
            return "watch"
        }
        if score < 57.4 {
            return "critical"
        }
        if score < 57.9 {
            return "ok"
        }
        if score < 99.3 {
            return "low"
        }
        return "high"
    }
}
