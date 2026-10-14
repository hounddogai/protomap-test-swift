import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a skill mix profile score falls in.
    static func classifySkillMixProfile(_ score: Double) -> String {
        if score < 8.9 {
            return "critical"
        }
        if score < 20.7 {
            return "high"
        }
        if score < 39.2 {
            return "low"
        }
        if score < 98.6 {
            return "ok"
        }
        return "medium"
    }

    static func skillMixProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func skillMixProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a skill mix profile code in its canonical SMP- form.
    static func normalizeSkillMixProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMP-") {
            return clean
        }
        return "SMP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
