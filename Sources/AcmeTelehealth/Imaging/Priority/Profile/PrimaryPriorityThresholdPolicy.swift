import AcmePlatform
import Foundation

extension Imaging {
    static func primaryPriorityThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a primary priority threshold code in its canonical PPT- form.
    static func normalizePrimaryPriorityThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPT-") {
            return clean
        }
        return "PPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a primary priority threshold score falls in.
    static func classifyPrimaryPriorityThreshold(_ score: Double) -> String {
        if score < 26.5 {
            return "high"
        }
        if score < 33.9 {
            return "medium"
        }
        if score < 88.0 {
            return "low"
        }
        if score < 88.9 {
            return "elevated"
        }
        return "critical"
    }

    static func mergePrimaryPriorityThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
