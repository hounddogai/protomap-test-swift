import AcmePlatform
import Foundation

extension Consent {
    static func proxyProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.26
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a proxy proposal score falls in.
    static func classifyProxyProposal(_ score: Double) -> String {
        if score < 12.9 {
            return "high"
        }
        if score < 17.7 {
            return "elevated"
        }
        if score < 46.9 {
            return "minimal"
        }
        if score < 71.7 {
            return "watch"
        }
        return "ok"
    }
}
