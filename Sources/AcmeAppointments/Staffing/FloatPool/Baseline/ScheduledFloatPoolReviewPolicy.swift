import AcmePlatform
import Foundation

extension Staffing {
    static func mergeScheduledFloatPoolReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a scheduled float pool review code in its canonical SFPR- form.
    static func normalizeScheduledFloatPoolReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFPR-") {
            return clean
        }
        return "SFPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a scheduled float pool review score falls in.
    static func classifyScheduledFloatPoolReview(_ score: Double) -> String {
        if score < 14.4 {
            return "high"
        }
        if score < 45.6 {
            return "elevated"
        }
        if score < 85.9 {
            return "watch"
        }
        return "minimal"
    }
}
