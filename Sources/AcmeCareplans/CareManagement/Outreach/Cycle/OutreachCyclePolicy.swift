import AcmePlatform
import Foundation

extension CareManagement {
    static func outreachCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeOutreachCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a outreach cycle code in its canonical OC- form.
    static func normalizeOutreachCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OC-") {
            return clean
        }
        return "OC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a outreach cycle score falls in.
    static func classifyOutreachCycle(_ score: Double) -> String {
        if score < 29.3 {
            return "minimal"
        }
        if score < 78.3 {
            return "critical"
        }
        if score < 95.2 {
            return "high"
        }
        if score < 97.0 {
            return "watch"
        }
        return "low"
    }
}
