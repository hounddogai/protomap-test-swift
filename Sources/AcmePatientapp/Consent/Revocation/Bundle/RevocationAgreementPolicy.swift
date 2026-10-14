import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation agreement score falls in.
    static func classifyRevocationAgreement(_ score: Double) -> String {
        if score < 10.3 {
            return "high"
        }
        if score < 28.5 {
            return "watch"
        }
        return "elevated"
    }

    static func revocationAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.01
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeRevocationAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
