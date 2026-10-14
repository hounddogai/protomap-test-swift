import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality schedule score falls in.
    static func classifyModalitySchedule(_ score: Double) -> String {
        if score < 26.6 {
            return "medium"
        }
        if score < 54.1 {
            return "ok"
        }
        if score < 65.7 {
            return "critical"
        }
        if score < 99.0 {
            return "minimal"
        }
        return "high"
    }

    /// Puts a modality schedule code in its canonical MS- form.
    static func normalizeModalityScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MS-") {
            return clean
        }
        return "MS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func modalityScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func modalityScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
