import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a weighted substitution profile code in its canonical WSP- form.
    static func normalizeWeightedSubstitutionProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WSP-") {
            return clean
        }
        return "WSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWeightedSubstitutionProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func weightedSubstitutionProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a weighted substitution profile score falls in.
    static func classifyWeightedSubstitutionProfile(_ score: Double) -> String {
        if score < 4.7 {
            return "low"
        }
        if score < 14.4 {
            return "medium"
        }
        return "high"
    }
}
