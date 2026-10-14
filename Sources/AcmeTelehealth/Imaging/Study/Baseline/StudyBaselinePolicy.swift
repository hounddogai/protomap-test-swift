import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a study baseline code in its canonical SB- form.
    static func normalizeStudyBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SB-") {
            return clean
        }
        return "SB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func studyBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeStudyBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a study baseline score falls in.
    static func classifyStudyBaseline(_ score: Double) -> String {
        if score < 8.9 {
            return "elevated"
        }
        if score < 18.2 {
            return "watch"
        }
        if score < 54.5 {
            return "high"
        }
        if score < 65.1 {
            return "critical"
        }
        return "low"
    }
}
