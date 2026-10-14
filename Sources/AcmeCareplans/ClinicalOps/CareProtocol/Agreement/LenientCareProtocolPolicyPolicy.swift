import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a lenient care protocol policy score falls in.
    static func classifyLenientCareProtocolPolicy(_ score: Double) -> String {
        if score < 9.9 {
            return "watch"
        }
        if score < 11.2 {
            return "ok"
        }
        if score < 27.7 {
            return "low"
        }
        if score < 31.6 {
            return "elevated"
        }
        return "minimal"
    }

    static func lenientCareProtocolPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func lenientCareProtocolPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
