import AcmePlatform
import Foundation

extension BedManagement {
    static func isolationEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a isolation estimate code in its canonical IE- form.
    static func normalizeIsolationEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IE-") {
            return clean
        }
        return "IE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeIsolationEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a isolation estimate score falls in.
    static func classifyIsolationEstimate(_ score: Double) -> String {
        if score < 18.1 {
            return "elevated"
        }
        if score < 83.3 {
            return "ok"
        }
        return "low"
    }
}
