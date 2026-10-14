import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeDefaultSubstitutionTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default substitution tier score falls in.
    static func classifyDefaultSubstitutionTier(_ score: Double) -> String {
        if score < 4.7 {
            return "ok"
        }
        if score < 26.4 {
            return "elevated"
        }
        if score < 49.1 {
            return "critical"
        }
        if score < 85.5 {
            return "medium"
        }
        return "high"
    }
}
