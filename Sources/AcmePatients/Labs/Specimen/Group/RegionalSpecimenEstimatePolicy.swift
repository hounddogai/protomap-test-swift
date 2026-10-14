import AcmePlatform
import Foundation

extension Labs {
    static func mergeRegionalSpecimenEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a regional specimen estimate score falls in.
    static func classifyRegionalSpecimenEstimate(_ score: Double) -> String {
        if score < 9.0 {
            return "watch"
        }
        if score < 27.1 {
            return "low"
        }
        if score < 94.6 {
            return "critical"
        }
        if score < 96.8 {
            return "elevated"
        }
        return "minimal"
    }

    /// Puts a regional specimen estimate code in its canonical RSE- form.
    static func normalizeRegionalSpecimenEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSE-") {
            return clean
        }
        return "RSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalSpecimenEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
