import AcmePlatform
import Foundation

extension RevenueCycle {
    static func claimProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a claim profile code in its canonical CP- form.
    static func normalizeClaimProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CP-") {
            return clean
        }
        return "CP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a claim profile score falls in.
    static func classifyClaimProfile(_ score: Double) -> String {
        if score < 5.6 {
            return "critical"
        }
        if score < 21.2 {
            return "watch"
        }
        if score < 49.1 {
            return "elevated"
        }
        return "ok"
    }
}
