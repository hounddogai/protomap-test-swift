import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a denial audit code in its canonical DA- form.
    static func normalizeDenialAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DA-") {
            return clean
        }
        return "DA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func denialAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.2
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a denial audit score falls in.
    static func classifyDenialAudit(_ score: Double) -> String {
        if score < 46.8 {
            return "low"
        }
        if score < 48.3 {
            return "critical"
        }
        return "watch"
    }
}
