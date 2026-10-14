import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a rolling accession budget score falls in.
    static func classifyRollingAccessionBudget(_ score: Double) -> String {
        if score < 75.6 {
            return "critical"
        }
        if score < 93.9 {
            return "high"
        }
        if score < 95.3 {
            return "ok"
        }
        if score < 98.2 {
            return "medium"
        }
        return "watch"
    }

    /// Puts a rolling accession budget code in its canonical RAB- form.
    static func normalizeRollingAccessionBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAB-") {
            return clean
        }
        return "RAB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
