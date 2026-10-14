import AcmePlatform
import Foundation

extension Staffing {
    static func manualShiftScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a manual shift score code in its canonical MSS- form.
    static func normalizeManualShiftScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MSS-") {
            return clean
        }
        return "MSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualShiftScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a manual shift score score falls in.
    static func classifyManualShiftScore(_ score: Double) -> String {
        if score < 7.8 {
            return "medium"
        }
        if score < 27.3 {
            return "watch"
        }
        if score < 64.0 {
            return "minimal"
        }
        if score < 81.4 {
            return "low"
        }
        return "critical"
    }
}
