import AcmePlatform
import Foundation

extension BedManagement {
    static func rollingDischargePlanSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling discharge plan summary score falls in.
    static func classifyRollingDischargePlanSummary(_ score: Double) -> String {
        if score < 10.5 {
            return "watch"
        }
        if score < 27.1 {
            return "minimal"
        }
        if score < 70.8 {
            return "high"
        }
        return "low"
    }

    /// Puts a rolling discharge plan summary code in its canonical RDPS- form.
    static func normalizeRollingDischargePlanSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDPS-") {
            return clean
        }
        return "RDPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
