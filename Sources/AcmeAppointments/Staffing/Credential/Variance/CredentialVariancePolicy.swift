import AcmePlatform
import Foundation

extension Staffing {
    static func credentialVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a credential variance code in its canonical CV- form.
    static func normalizeCredentialVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CV-") {
            return clean
        }
        return "CV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a credential variance score falls in.
    static func classifyCredentialVariance(_ score: Double) -> String {
        if score < 11.7 {
            return "minimal"
        }
        if score < 14.3 {
            return "critical"
        }
        if score < 35.3 {
            return "elevated"
        }
        return "high"
    }

    static func mergeCredentialVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
