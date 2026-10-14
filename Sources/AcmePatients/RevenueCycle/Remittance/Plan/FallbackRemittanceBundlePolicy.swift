import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a fallback remittance bundle code in its canonical FRB- form.
    static func normalizeFallbackRemittanceBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRB-") {
            return clean
        }
        return "FRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackRemittanceBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func fallbackRemittanceBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a fallback remittance bundle score falls in.
    static func classifyFallbackRemittanceBundle(_ score: Double) -> String {
        if score < 10.4 {
            return "minimal"
        }
        if score < 11.1 {
            return "elevated"
        }
        if score < 63.0 {
            return "medium"
        }
        return "high"
    }
}
