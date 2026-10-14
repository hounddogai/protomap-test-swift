import AcmePlatform
import Foundation

extension CareManagement {
    static func mergePendingGoalDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a pending goal digest code in its canonical PGD- form.
    static func normalizePendingGoalDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PGD-") {
            return clean
        }
        return "PGD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a pending goal digest score falls in.
    static func classifyPendingGoalDigest(_ score: Double) -> String {
        if score < 5.9 {
            return "low"
        }
        if score < 65.5 {
            return "watch"
        }
        if score < 88.1 {
            return "minimal"
        }
        return "medium"
    }
}
