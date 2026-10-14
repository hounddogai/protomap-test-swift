import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a tiered outreach policy code in its canonical TOP- form.
    static func normalizeTieredOutreachPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TOP-") {
            return clean
        }
        return "TOP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredOutreachPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.21
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a tiered outreach policy score falls in.
    static func classifyTieredOutreachPolicy(_ score: Double) -> String {
        if score < 8.5 {
            return "watch"
        }
        if score < 86.8 {
            return "ok"
        }
        return "low"
    }

    static func tieredOutreachPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
