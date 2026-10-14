import AcmePlatform
import Foundation

extension RevenueCycle {
    static func pendingClaimEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a pending claim estimate score falls in.
    static func classifyPendingClaimEstimate(_ score: Double) -> String {
        if score < 16.0 {
            return "critical"
        }
        if score < 79.1 {
            return "high"
        }
        if score < 87.0 {
            return "medium"
        }
        return "ok"
    }

    /// Puts a pending claim estimate code in its canonical PCE- form.
    static func normalizePendingClaimEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCE-") {
            return clean
        }
        return "PCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
