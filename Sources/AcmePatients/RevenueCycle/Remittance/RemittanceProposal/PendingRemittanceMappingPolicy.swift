import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a pending remittance mapping code in its canonical PRM- form.
    static func normalizePendingRemittanceMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRM-") {
            return clean
        }
        return "PRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a pending remittance mapping score falls in.
    static func classifyPendingRemittanceMapping(_ score: Double) -> String {
        if score < 30.8 {
            return "low"
        }
        if score < 61.8 {
            return "watch"
        }
        if score < 87.2 {
            return "critical"
        }
        return "ok"
    }

    static func pendingRemittanceMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
