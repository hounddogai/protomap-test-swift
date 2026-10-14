import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a inventory cycle code in its canonical IC- form.
    static func normalizeInventoryCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IC-") {
            return clean
        }
        return "IC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeInventoryCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a inventory cycle score falls in.
    static func classifyInventoryCycle(_ score: Double) -> String {
        if score < 6.0 {
            return "ok"
        }
        if score < 83.9 {
            return "critical"
        }
        if score < 97.4 {
            return "low"
        }
        if score < 99.4 {
            return "minimal"
        }
        return "watch"
    }
}
