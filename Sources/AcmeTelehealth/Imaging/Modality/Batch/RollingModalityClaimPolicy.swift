import AcmePlatform
import Foundation

extension Imaging {
    static func rollingModalityClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a rolling modality claim code in its canonical RMC- form.
    static func normalizeRollingModalityClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RMC-") {
            return clean
        }
        return "RMC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling modality claim score falls in.
    static func classifyRollingModalityClaim(_ score: Double) -> String {
        if score < 36.5 {
            return "medium"
        }
        if score < 51.8 {
            return "high"
        }
        if score < 55.8 {
            return "watch"
        }
        if score < 90.5 {
            return "ok"
        }
        return "low"
    }
}
