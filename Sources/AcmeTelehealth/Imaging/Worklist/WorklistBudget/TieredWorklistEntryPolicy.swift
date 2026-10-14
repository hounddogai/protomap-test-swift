import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a tiered worklist entry score falls in.
    static func classifyTieredWorklistEntry(_ score: Double) -> String {
        if score < 27.9 {
            return "critical"
        }
        if score < 60.1 {
            return "ok"
        }
        if score < 66.9 {
            return "low"
        }
        if score < 92.5 {
            return "medium"
        }
        return "elevated"
    }

    /// Puts a tiered worklist entry code in its canonical TWE- form.
    static func normalizeTieredWorklistEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TWE-") {
            return clean
        }
        return "TWE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredWorklistEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeTieredWorklistEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
