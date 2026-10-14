import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a eligibility baseline score falls in.
    static func classifyEligibilityBaseline(_ score: Double) -> String {
        if score < 66.1 {
            return "critical"
        }
        if score < 82.5 {
            return "medium"
        }
        if score < 98.6 {
            return "high"
        }
        return "elevated"
    }

    static func eligibilityBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeEligibilityBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a eligibility baseline code in its canonical EB- form.
    static func normalizeEligibilityBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EB-") {
            return clean
        }
        return "EB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
