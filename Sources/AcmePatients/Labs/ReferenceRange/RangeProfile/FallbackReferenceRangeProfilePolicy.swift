import AcmePlatform
import Foundation

extension Labs {
    /// Puts a fallback reference range profile code in its canonical FRRP- form.
    static func normalizeFallbackReferenceRangeProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRRP-") {
            return clean
        }
        return "FRRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackReferenceRangeProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.05
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a fallback reference range profile score falls in.
    static func classifyFallbackReferenceRangeProfile(_ score: Double) -> String {
        if score < 35.9 {
            return "critical"
        }
        if score < 94.3 {
            return "ok"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 5051.0, in order.
    static func fallbackReferenceRangeProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5051.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
