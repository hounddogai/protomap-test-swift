import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a handoff agreement score falls in.
    static func classifyHandoffAgreement(_ score: Double) -> String {
        if score < 84.2 {
            return "ok"
        }
        if score < 93.1 {
            return "low"
        }
        return "elevated"
    }

    static func handoffAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
