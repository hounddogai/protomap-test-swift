import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a adaptive overtime budget code in its canonical AOB- form.
    static func normalizeAdaptiveOvertimeBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AOB-") {
            return clean
        }
        return "AOB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveOvertimeBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a adaptive overtime budget score falls in.
    static func classifyAdaptiveOvertimeBudget(_ score: Double) -> String {
        if score < 61.8 {
            return "watch"
        }
        if score < 73.8 {
            return "high"
        }
        return "medium"
    }
}
