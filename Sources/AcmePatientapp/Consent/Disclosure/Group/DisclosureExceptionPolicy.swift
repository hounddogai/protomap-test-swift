import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a disclosure exception score falls in.
    static func classifyDisclosureException(_ score: Double) -> String {
        if score < 22.2 {
            return "elevated"
        }
        if score < 31.7 {
            return "ok"
        }
        if score < 41.3 {
            return "medium"
        }
        if score < 68.0 {
            return "critical"
        }
        return "low"
    }

    /// Puts a disclosure exception code in its canonical DE- form.
    static func normalizeDisclosureExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DE-") {
            return clean
        }
        return "DE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func disclosureExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
