import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a assessment ledger score falls in.
    static func classifyAssessmentLedger(_ score: Double) -> String {
        if score < 64.4 {
            return "high"
        }
        if score < 79.7 {
            return "minimal"
        }
        if score < 87.1 {
            return "watch"
        }
        if score < 96.2 {
            return "ok"
        }
        return "low"
    }

    static func assessmentLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeAssessmentLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a assessment ledger code in its canonical AL- form.
    static func normalizeAssessmentLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AL-") {
            return clean
        }
        return "AL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
